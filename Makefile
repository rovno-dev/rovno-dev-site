.PHONY: up stop rebuild help logs

# Default environment is prod
ENV ?= prod
ENV_FILE := .env.$(ENV)
CONTAINERS ?= ""

# 1. Base Docker Compose Command
# Always loads standard docker-compose.yml and the chosen env file
DOCKER_CMD := docker compose --profile $(ENV) --env-file $(ENV_FILE) -f docker-compose.yml

# 2. Add Dev Overrides
# If ENV=dev, append the dev compose file. Docker automatically merges them.
ifeq ($(ENV),dev)
	DOCKER_CMD += -f docker-compose.dev.yml
endif

help:
	@echo "Usage:"
	@echo "  make up [ENV=dev|prod]      - Start services"
	@echo "  make stop                   - Stop all services"
	@echo "  make rebuild [ENV=dev|prod] - Rebuild and restart"
	@echo "  make logs                   - View logs"

up:
	@echo "Starting environment: $(ENV)"
	$(DOCKER_CMD) up -d

stop:
	@echo "Stopping environment: $(ENV)"
	$(DOCKER_CMD) stop

rebuild:
	@echo "Rebuilding environment: $(ENV)"
	$(DOCKER_CMD) up -d --build $(CONTAINERS) --force-recreate

logs:
	$(DOCKER_CMD) logs -f

clean:
	docker rm -f $$(docker ps -aq) || true

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