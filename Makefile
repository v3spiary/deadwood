.PHONY: up down logs backend frontend celery test debug

# Поднимает весь dev стек
up:
	docker-compose -f docker-compose/docker-compose-dev.yml up -d --build

# Сносит весь dev стек (вместе с volumes)
down:
	docker-compose -f docker-compose/docker-compose-dev.yml down -v

# Только собрать весь dev-стек (С КЕШЕМ)
build:
	docker-compose -f docker-compose/docker-compose-dev.yml build

# Перезагрузка контейнеров
reload:
	docker-compose -f docker-compose/docker-compose-dev.yml restart

# Только собрать весь dev-стек (БЕЗ КЕША)
rebuild:
	docker-compose -f docker-compose/docker-compose-dev.yml build --no-cache

# Только собрать только dev-фронт (БЕЗ КЕША) / зачем-то было нужно, зачем - не помню)
rebuild-frontend:
	docker-compose -f docker-compose/docker-compose-dev.yml build --no-cache frontend

# Выводит логи dev стека
logs:
	docker-compose -f docker-compose/docker-compose-dev.yml logs -f

# Выводит только логи dev-бэкэнда
backend-logs:
	docker-compose -f docker-compose/docker-compose-dev.yml logs -f backend

# Выводит только логи dev-фронта
frontend-logs:
	docker-compose -f docker-compose/docker-compose-dev.yml logs -f frontend

# Выводит только логи dev-воркера
celery-logs:
	docker-compose -f docker-compose/docker-compose-dev.yml logs -f celery

# Прокинуть шелл в контейнер бэкэнда
backend:
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend bash

# Прокинуть шелл в контейнер фронта
frontend:
	docker-compose -f docker-compose/docker-compose-dev.yml exec frontend sh

# Прокидывает шелл в postgres контейнер
db:
	docker-compose -f docker-compose/docker-compose-dev.yml exec db psql -U postgres deadwood_dev

# Прогон модульных тестов бэка
test:
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend python3 manage.py test tracker --settings=config.test_settings

# Сгенерировать скрипты миграции на лету
migrations:
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend python3 manage.py makemigrations

# Применить миграции на лету
migrate:
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend python3 manage.py migrate

# Прокинуть Django-вский шелл в бэке (не bash!)
shell:
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend python3 manage.py shell_plus

# Доустановить на лету библиотеки (бэкэнд)
pip:
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend pip3 install -r requirements.txt

# Дропнуть базу данных в dev-окружении и выполнить миграции (если наебнулась схема)
drop:
	docker-compose -f docker-compose/docker-compose-dev.yml down -v db
	docker-compose -f docker-compose/docker-compose-dev.yml up -d db
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend python3 manage.py makemigrations
	docker-compose -f docker-compose/docker-compose-dev.yml exec backend python3 manage.py migrate

# Запуск llm-модели в Ollama
llm:
	docker-compose -f docker-compose/docker-compose-dev.yml exec ollama ollama run deepseek-r1:1.5b

# Тест сборки WAF (prod стек)
waf:
	docker-compose -f docker-compose/docker-compose-prod.yml build waf
