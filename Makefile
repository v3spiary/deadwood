dev:
	docker compose -f docker-compose/docker-compose-dev.yml up -d --build

stage:
	docker compose -f docker-compose/docker-compose-stage.yml up -d --build

kill:
	docker compose -f docker-compose/docker-compose-dev.yml down -v || true
	docker compose -f docker-compose/docker-compose-stage.yml down -v || true

.PHONY: dev stage kill
