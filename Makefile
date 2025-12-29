dev:
	docker compose -f docker-compose/docker-compose-dev.yml up -d --build

prod:
	docker compose -f docker-compose/docker-compose-prod.yml up -d --build

kill:
	docker compose -f docker-compose/docker-compose-dev.yml down -v

.PHONY: dev prod kill
