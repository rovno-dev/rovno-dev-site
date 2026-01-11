.PHONY: up stop rebuild help logs

ENV ?= prod

COMPOSE_FILE :=
ifeq ($(ENV),dev)
	ifneq (,$(wildcard .env.dev))
			include .env.dev
			export
	endif
	ENV_FILE_FLAG := --env-file .env.dev
	COMPOSE_ARGS := $(COMPOSE_FILE) --profile dev $(ENV_FILE_FLAG)
else
	ifneq (,$(wildcard .env.prod))
			include .env.prod
			export
	endif
	ENV_FILE_FLAG := --env-file .env.prod
	COMPOSE_ARGS := $(COMPOSE_FILE) --profile prod $(ENV_FILE_FLAG)
endif

help:
	@echo "Usage:"
	@echo "  make up [ENV=dev|prod]      - Start services (runs npm run dev locally if ENV=dev)"
	@echo "  make down                   - Stop all services"
	@echo "  make rebuild [ENV=dev|prod] - Rebuild and restart (force recreate)"
	@echo "  make logs                   - View logs"

up:
	@echo "Starting environment: $(ENV)"
ifeq ($(ENV),dev)
	@echo "1. Starting Backend Services (Docker)..."
	docker compose $(COMPOSE_ARGS) up -d
	@echo "2. Waiting for DB/Backend to warm up..."
	@sleep 2
	@echo "3. Starting Local Frontend..."
	cd frontend && npm run dev
else
	# Prod Mode
	docker compose $(COMPOSE_ARGS) up -d
endif

stop:
	docker compose stop

rebuild:
	@echo "Rebuilding environment: $(ENV)"
ifeq ($(ENV),dev)
	# Rebuild backend services with force-recreate
	docker compose $(COMPOSE_ARGS) up -d --build --force-recreate
# 	@echo "Starting Local Frontend..."
# 	cd frontend && npm run dev
else
	# Prod Mode
	docker compose $(COMPOSE_ARGS) up -d --build --force-recreate
endif

logs:
	docker compose $(COMPOSE_ARGS) logs -f