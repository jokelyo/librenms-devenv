
# -------------------------------------------------------------------------------------------
# VARIABLES: Variable declarations to be used within make to generate commands.
# -------------------------------------------------------------------------------------------
# Variables that are specific to each project.
#PROJECT      := $(shell basename `pwd`)
#REPO         := local
#REGISTRY     := nautobot
#COVERAGE_PCT := 40
DEVELOP_DIR := "development"

# These variables should be the same across all projects
BASE = VERSION=$(VERSION) docker compose --project-directory ${DEVELOP_DIR} -f "${DEVELOP_DIR}/docker-compose.yml"

default: help

cli: .env ## Exec into an already running Nautobot container. Start the container if stopped.
ifeq (,$(findstring librenms,$($BASE ps --services --filter status=running)))
	@make start
endif
	@$(BASE) exec librenms bash
.PHONY: cli

debug: .env ## Launch docker-compose environment in attached mode. Use `make debug agg` to launch aggregate instance as well.
	@$(BASE) up
.PHONY: debug

logs: .env ## Tail the logs of the compose environment.
	@$(BASE) logs -f --tail=500
.PHONY: logs

start: .env ## Start the docker-compose environment in detached mode. Use `make debug agg` to launch aggregate instance as well.
	@ENV=local $(BASE) up -d
.PHONY: start

stop: ## Stop and bring down all the running containers started by compose.
	@$(BASE) down
.PHONY: stop

restart: .env ## Restart docker containers.
	@$(BASE) restart
.PHONY: restart

destroy: ## Destroy all the docker containers and attached volumes. This will delete all data!!
	@$(BASE) down --volumes
.PHONY: destroy


# -------------------------------------------------------------------------------------------
# DOCKER/BUILD: Building of containers and pushing to registries
# -------------------------------------------------------------------------------------------
build:  ## Builds a new development container. Does not use cached data.
	@VERSION=${VERSION} $(BASE) build nautobot --no-cache
.PHONY: build

# -------------------------------------------------------------------------------------------
# GENERAL: utility commands for environment management.
# -------------------------------------------------------------------------------------------
.env:
	@if [ ! -f "${PWD}/${DEVELOP_DIR}/.env" ]; then \
	   echo "Creating environment file..."; \
	   cp ${PWD}/${DEVELOP_DIR}/.env.example ${PWD}/${DEVELOP_DIR}/.env; \
	fi
.PHONY: .env

_env-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		echo "Please check README.md or Makefile for variables required."; \
		echo "(╯°□°）╯︵ ┻━┻"; \
		exit 1; \
	fi
.PHONY: _env-%

help:
	@echo "\033[1m\033[01;32m\
	$(shell echo $(PROJECT) | tr  '[:lower:]' '[:upper:]') $(VERSION) \
	\033[00m\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' \
	$(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
