.PHONY: up stop rebuild help logs

ENV ?= prod

# 1. Determine the Env File
ENV_FILE := .env.$(ENV)

# 2. Safely include the env file if it exists
# We use -include to ignore errors if file is missing, 
# but we check for directory existence to avoid the "read directory" error.
ifneq (,$(wildcard $(ENV_FILE)))
    # Ensure it is a file, not a dir, before including
    ifneq ($(wildcard $(ENV_FILE)/.*),)
        $(error $(ENV_FILE) is a directory! It must be a file)
    else
        include $(ENV_FILE)
        export
    endif
endif

# 3. Construct Docker Compose Arguments
# Start with the profile and env file
COMPOSE_ARGS := --profile $(ENV) --env-file $(ENV_FILE)

# 4. Safely Handle COMPOSE_FILE
# Only add it if the variable is set and not empty. 
# IMPORTANT: We must prepend '-f' so Docker knows it's a file, not a command.
ifneq ($(strip $(COMPOSE_FILE)),)
    COMPOSE_ARGS := -f $(COMPOSE_FILE) $(COMPOSE_ARGS)
endif

help:
	@echo "Usage:"
	@echo "  make up [ENV=dev|prod]      - Start services"
	@echo "  make down                   - Stop all services"
	@echo "  make rebuild [ENV=dev|prod] - Rebuild and restart"
	@echo "  make logs                   - View logs"

up:
	@echo "Starting environment: $(ENV)"
ifeq ($(ENV),dev)
	@echo "1. Starting Backend Services (Docker)..."
	docker compose $(COMPOSE_ARGS) up -d
	@echo "2. Waiting for DB/Backend to warm up..."
	@sleep 2
	@echo "3. Starting Local Frontend..."
	# Ensure 'frontend' dir exists before cd
	@if [ -d "frontend" ]; then cd frontend && npm run dev; else echo "Frontend directory not found"; fi
else
	# Prod Mode
	docker compose $(COMPOSE_ARGS) up -d
endif

stop:
	docker compose stop

rebuild:
	@echo "Rebuilding environment: $(ENV)"
	docker compose $(COMPOSE_ARGS) up -d --build --force-recreate

logs:
	docker compose $(COMPOSE_ARGS) logs -f


# =====
# Git actions
# =====

push-all:
	@echo "=== Pushing submodules ==="
	git submodule foreach 'git push || echo "Failed to push"'
	@echo "=== Pushing parent repo ==="
	git push --recurse-submodules=on-demand

checkoutAll:
ifndef BRANCH
	$(error BRANCH is undefined. Usage: make checkoutAll BRANCH=main)
endif
	@echo "=== Checking out $(BRANCH) in all submodules ==="
	git submodule foreach 'git checkout $(BRANCH) || echo "Branch $(BRANCH) not found in $$name"'

merge-all:
ifndef BRANCH
	$(error BRANCH is undefined. Usage: make merge-all BRANCH=origin/main)
endif
	@echo "=== Merging $(BRANCH) into all submodules ==="
	git submodule foreach 'git merge $(BRANCH) || echo "Failed to merge in $$name"'

pull-all:
	@echo "=== Pulling and Re-basing Submodules ==="
	git submodule update --recursive --remote --rebase

commit-all:
	@echo "=== Committing Submodules ==="
	git submodule foreach 'git add -A && git commit -m "$(MSG)" || echo "Nothing to commit in $$name"'
	@echo "=== Committing Parent ==="
	git add -A
	git commit -m "$(MSG)"