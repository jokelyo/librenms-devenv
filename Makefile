# -------------------------------------------------------------------------------------------
# VARIABLES: Variable declarations to be used within make to generate commands.
# -------------------------------------------------------------------------------------------
# Variables that are specific to each project.
#PROJECT      := $(shell basename `pwd`)
#REPO         := local
#REGISTRY     := librenms
#COVERAGE_PCT := 40
DEVELOP_DIR := "development"
LIBRENMS_TOKEN := $(shell openssl rand -hex 16)

# These variables should be the same across all projects
BASE = VERSION=$(VERSION) docker compose --project-directory ${DEVELOP_DIR} -f "${DEVELOP_DIR}/docker-compose.yml"
TERRAFORM = terraform -chdir=terraform

default: help

setup: ## Set up LibreNMS and Terraform environments
	@echo "Setting up LibreNMS and Terraform environment..."
	@if [ -f ${DEVELOP_DIR}/.env ]; then \
	   echo "Error: ${DEVELOP_DIR}/.env file already exists, exiting setup."; \
	   exit 1; \
	fi
	@make .env
	@echo "LIBRENMS_TOKEN=${LIBRENMS_TOKEN}" >> ${DEVELOP_DIR}/.env
	@make start
	@echo "Waiting 20 sec for LibreNMS services to start..."
	@sleep 20
	@make librenms-admin

	@echo "Creating terraform/terraform.tfvars file..."
	@grep -v librenms terraform/terraform.tfvars.example > terraform/terraform.tfvars
	@chmod 0600 terraform/terraform.tfvars
	@echo 'librenms_host = "http://localhost:8000/"' >> terraform/terraform.tfvars
	@echo 'librenms_token = "${LIBRENMS_TOKEN}"' >> terraform/terraform.tfvars

	@echo "Please enter your google project ID: "; \
	read -r GOOGLE_PROJECT_ID; \
	sed -i '' "s/your-gcp-project-id/$${GOOGLE_PROJECT_ID}/" terraform/terraform.tfvars

	@sed -i '' "s/YOUR_PUBLIC_IP/$$(curl -s ifconfig.me)/" terraform/terraform.tfvars

	@echo "\n\nLibreNMS URL: http://localhost:8000/\nLibreNMS User: admin\nLibreNMS Password: admin\n\n"
	@echo "API Token: ${LIBRENMS_TOKEN}"
	@echo "API Example: curl -H \"X-Auth-Token: ${LIBRENMS_TOKEN}\" http://localhost:8000/api/v0/devices\n\n"

	@echo "Next Steps:"
	@echo " 1. Run 'gcloud auth login --update-adc' to authenticate with Google Cloud."
	@echo " 2. Run 'make tf-init' to initialize Terraform."
	@echo " 3. Run 'make tf-plan' to see the resources that will be created."
	@echo " 4. Run 'make tf-apply' to apply the Terraform configuration."
.PHONY: setup

cli: .env ## Exec into an already running LibreNMS container. Start the container if stopped.
ifeq (,$(findstring librenms,$($BASE ps --services --filter status=running)))
	@make start
endif
	@$(BASE) exec librenms bash
.PHONY: cli

debug: .env ## Launch docker-compose environment in attached mode.
	@$(BASE) up
.PHONY: debug

librenms-admin:
	@echo "Creating LibreNMS admin user and API token..."
	@$(BASE) exec librenms lnms user:add -r admin -p admin admin
	@$(BASE) exec librenms sh -c 'mariadb -h db -u $$MYSQL_USER -p$$MYSQL_PASSWORD -D librenms \
       -e "insert into api_tokens (id,user_id,token_hash,description,disabled) VALUES (1,1,\"$$LIBRENMS_TOKEN\",\"\",0);"'
.PHONY: librenms-admin

logs: .env ## Tail the logs of the compose environment.
	@$(BASE) logs -f --tail=500
.PHONY: logs

start: .env ## Start the docker-compose environment in detached mode.
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

destroy-all: tf-destroy destroy ## DESTROY EVERYTHING: all docker containers and volumes and all Terraform resources.
.PHONY: destroy-all

tf-init: .tfvars ## terraform init
	$(TERRAFORM) init
.PHONY: tf-init

tf-plan: .tfvars ## terraform plan
	$(TERRAFORM) plan
.PHONY: tf-plan

tf-apply: .tfvars ## terraform apply
	$(TERRAFORM) apply
.PHONY: tf-apply

tf-destroy: .tfvars ## terraform destroy
	$(TERRAFORM) destroy
.PHONY: tf-destroy

tf-lint: ## Run tflint to check Terraform code for issues.
	@if [ -z "$(shell which tflint)" ]; then \
		echo "tflint is not installed."; \
		exit 1; \
	fi
	@tflint --chdir=terraform
.PHONY: tf-lint

# -------------------------------------------------------------------------------------------
# GENERAL: utility commands for environment management.
# -------------------------------------------------------------------------------------------
.env:
	@if [ ! -f "${PWD}/${DEVELOP_DIR}/.env" ]; then \
	   echo "Creating ${DEVELOP_DIR}/.env file..."; \
	   cp ${PWD}/${DEVELOP_DIR}/.env.example ${PWD}/${DEVELOP_DIR}/.env; \
	   chmod 0600 ${PWD}/${DEVELOP_DIR}/.env; \
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

.tfvars:
	@if [ ! -f "terraform/terraform.tfvars" ]; then \
	   echo "Creating terraform/terraform.tfvars file..."; \
	   cp terraform/terraform.tfvars.example terraform/terraform.tfvars; \
	   chmod 0600 terraform/terraform.tfvars; \
	fi
.PHONY: .tfvars

help:
	@echo "\033[1m\033[01;32m\
	$(shell echo $(PROJECT) | tr  '[:lower:]' '[:upper:]') $(VERSION) \
	\033[00m\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' \
	$(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help


