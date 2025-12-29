# STAGE 1: SETUP ENV
FROM python:3.11-slim AS base

ENV PYTHONUNBUFFERED=1
ENV PIP_DEFAULT_TIMEOUT=1000
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    libpq-dev \
    libjpeg-dev \ 
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libtk8.6 \
    libtcl8.6 \
    python3-dev \
    make \
    cmake \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

WORKDIR /app

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

# Создаем группу и пользователя раньше
RUN groupadd -g 1000 hismind && useradd -u 1000 -g hismind -m hismind

# Создаем директорию для логов с правильными правами
RUN mkdir -p /var/log/django && \
    touch /var/log/django/django.log && \
    touch /var/log/django/django_error.log && \
    touch /var/log/django/celery.log && \
    chown -R hismind:hismind /var/log/django && \
    chmod 755 /var/log/django

# STAGE 2: DRF REST API
FROM base AS server

COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

COPY . /app/

EXPOSE 8000

# Изменяем владельца приложения
RUN chown -R hismind:hismind /app

USER hismind

ENTRYPOINT ["sh", "./entrypoint.sh"]

# STAGE 3: CELERY WORKER
FROM base AS worker

COPY . /app/

# Изменяем владельца приложения
RUN chown -R hismind:hismind /app

USER hismind

ENTRYPOINT celery -A config worker --loglevel=info --concurrency=4

# STAGE 4: CELERY BEAT
FROM worker AS beat 

ENTRYPOINT celery -A config beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
