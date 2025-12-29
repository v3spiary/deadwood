"""Приложение для дневника."""

from django.apps import AppConfig


class DiaryConfig(AppConfig):
    """Класс конфигурации приложения."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "diary"
