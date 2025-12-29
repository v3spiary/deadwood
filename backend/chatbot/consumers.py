import json
import threading
import urllib.request
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.db import transaction

logger = logging.getLogger(__name__)

def _generate_ai_sync(chat_id, prompt):
    """Синхронная генерация в отдельном потоке."""
    try:
        from chatbot.models import Chat, Message
        from asgiref.sync import async_to_sync
        from channels.layers import get_channel_layer

        channel_layer = get_channel_layer()
        group_name = f"chat_{chat_id}"
        full_response = ""

        req = urllib.request.Request(
            "http://ollama:11434/api/generate",
            data=json.dumps({
                "model": "evilfreelancer/o1_gigachat:20b",
                "system": "Ты — эмпатичный цифровой психолог. Твоя роль — поддерживать диалог, выслушивать, задавать уточняющие вопросы и помогать пользователю разобраться в его чувствах. Ты всегда отвечаешь ТОЛЬКО на русском языке. КРИТИЧЕСКИ ВАЖНО: Любые внутренние рассуждения, анализ, размышления или промежуточные шаги ты должен держать в уме и НИКОГДА не включать в итоговый ответ пользователю. Твой ответ должен быть плавным, цельным, естественным и сразу готовым для чтения пользователем. Не используй теги <Thought>, <Output> или любые другие форматы, кроме обычного текста.",
                "prompt": f"{prompt}",
                "stream": True
            }).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with urllib.request.urlopen(req) as resp:
            for line in resp:
                line = line.strip()
                if not line:
                    continue
                data = json.loads(line.decode())
                token = data.get("response", "")
                if token:
                    full_response += token
                    async_to_sync(channel_layer.group_send)(
                        group_name,
                        {"type": "ai_chunk", "chunk": token},
                    )
                if data.get("done"):
                    break

        # СОХРАНЯЕМ В БД
        ai_msg = Message.objects.create(
            chat_id=chat_id,
            content=full_response,
            message_type="text",
            sender=None,
        )

        async_to_sync(channel_layer.group_send)(
            group_name,
            {"type": "ai_complete", "message_id": str(ai_msg.id)},
        )

    except Exception as e:
        logger.error(f"[AI Thread] ERROR: {e}", exc_info=True)

class ServiceChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        from chatbot.models import Chat, Message
        self.user = self.scope["user"]
        self.chat_id = self.scope["url_route"]["kwargs"]["chat_id"]

        if self.user.is_anonymous:
            await self.close()
            return

        exists = await database_sync_to_async(
            lambda: Chat.objects.filter(id=self.chat_id, owner=self.user).exists()
        )()
        if not exists:
            await self.close()
            return

        self.room_group_name = f"chat_{self.chat_id}"
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, "room_group_name"):
            await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        content = data.get("message", "").strip()
        if not content:
            return

        # 1. Сохраняем user-сообщение с коммитом
        user_msg = await self._save_user_message(content)

        # 2. Отправляем эхо
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "user_message",
                "message_id": str(user_msg.id),
                "content": content,
            },
        )

        # 3. Запускаем AI в отдельном потоке (не блокирует WS)
        threading.Thread(
            target=_generate_ai_sync,
            args=(self.chat_id, content),
            daemon=True
        ).start()

    # --- Обработчики ---
    async def user_message(self, event):
        await self.send(text_data=json.dumps({
            "type": "user_message",
            "message_id": event["message_id"],
            "content": event["content"],
        }))

    async def ai_chunk(self, event):
        await self.send(text_data=json.dumps({
            "type": "ai_chunk",
            "chunk": event["chunk"],
        }))

    async def ai_complete(self, event):
        await self.send(text_data=json.dumps({
            "type": "ai_complete",
            " race_id": event["message_id"],
        }))

    # --- DB ---
    @database_sync_to_async
    def _save_user_message(self, content):
        from chatbot.models import Chat, Message
        with transaction.atomic():
            chat = Chat.objects.select_for_update().get(id=self.chat_id)
            return Message.objects.create(
                chat=chat,
                sender=self.user,
                content=content,
                message_type="text",
            )