"""Приложение для авторизации."""

from django.apps import AppConfig


class AuthAppConfig(AppConfig):
    """Класс конфигурации приложения."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "auth_app"
