"""Маршрутизация для веб-сокетов в приложении чатбота."""

from django.urls import re_path

from . import consumers

websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<chat_id>[^/]+)/$", consumers.ServiceChatConsumer.as_asgi()),
]
