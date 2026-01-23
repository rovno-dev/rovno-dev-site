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


# =====
# Git actions
# =====

# Commit everything
commit-all:
	@echo "=== Committing Submodules ==="
	git submodule foreach 'git add -A && git commit -m "$(MSG)" || echo "Nothing to commit in $$name"'
	@echo "=== Committing Parent ==="
	git add -A
	git commit -m "$(MSG)"

# Push safely
push-all:
	@echo "=== Pushing submodules ==="
	git submodule foreach 'git push || echo "Failed to push"'
	@echo "=== Pushing parent repo ==="
	git push --recurse-submodules=on-demand

# Checkout a branch in all submodules (Required before merging!)
checkout-all:
ifndef BRANCH
	$(error BRANCH is undefined. Usage: make checkoutAll BRANCH=main)
endif
	@echo "=== Checking out $(BRANCH) in all submodules ==="
	git submodule foreach 'git checkout $(BRANCH) || echo "Branch $(BRANCH) not found in $$name"'

# Merge a specific branch into current submodule state
merge-all:
ifndef BRANCH
	$(error BRANCH is undefined. Usage: make mergeAll BRANCH=origin/main)
endif
	@echo "=== Merging $(BRANCH) into all submodules ==="
	git submodule foreach 'git merge $(BRANCH) || echo "Failed to merge in $$name"'

# Pull/Update (Fetch new code)
pull-all:
	@echo "=== Pulling and Re-basing Submodules ==="
	# --remote fetches the latest from upstream
	# --rebase ensures you apply your changes on top of upstream
	git submodule update --recursive --remote --rebase