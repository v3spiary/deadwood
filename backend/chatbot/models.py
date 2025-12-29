"""Модели базы данных для приложения чат-бота."""

import uuid

from django.contrib.auth.models import User
from django.db import models


class Chat(models.Model):
    """Описывает модель чата."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(default="Новый чат", max_length=255)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name="chats")
    # Flags for pinning and soft-delete
    is_pinned = models.BooleanField(default=False)
    deleted = models.BooleanField(default=False)  # For logical delete[citation:4]
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        """Метаданные модели."""

        verbose_name = "Чат"
        verbose_name_plural = "Чаты"
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "name"], name="unique_chat_per_user"
            )
        ]

    def __str__(self):
        return f"{self.name} ({self.owner})"


class Message(models.Model):
    """Описывает модель сообщения в чате."""

    MESSAGE_TYPES = [
        ("text", "Text"),
        ("system", "System"),  # For service messages
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chat = models.ForeignKey(Chat, related_name="messages", on_delete=models.CASCADE)
    # For a user-to-service chat, the sender can be either the user or the system
    sender = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL)
    # A null sender could indicate a system/service message
    content = models.TextField()
    message_type = models.CharField(
        max_length=20, choices=MESSAGE_TYPES, default="text"
    )
    # Track if a message was edited
    is_edited = models.BooleanField(default=False)
    # Soft delete for messages (e.g., "deleted for me")
    deleted_for_owner = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        """Метаданные модели."""

        verbose_name = "Сообщение"
        verbose_name_plural = "Сообщения"
        ordering = ("created_at",)

    def __str__(self):
        sender_name = self.sender.username if self.sender else "System"
        return f"Сообщение от {sender_name} в {self.chat.name}"
