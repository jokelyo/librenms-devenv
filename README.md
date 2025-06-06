# librenms-devenv
Local dev instance of LibreNMS. 
Test the [LibreNMS Terraform provider](https://github.com/jokelyo/terraform-provider-librenms) with simple GCP environment setup.

## Requirements
* OSX or *nix-compatible OS
* Docker
* Docker Compose
* Make
* Terraform
* [gcloud](https://cloud.google.com/sdk/docs/install) (for GCP environment)
* A Google Cloud account with billing enabled (for GCP environment)
* A Google Cloud project created (for GCP environment)
* openssl (for generating API token)

> [!WARNING]
> To prevent polling performance issues inside the librenms container, you should enable the `Use kernel networking for UDP` option in the Docker Desktop settings.
> Settings -> Resources -> Network -> Use kernel networking for UDP

> [!WARNING]
> Applying this plan will generate cloud charges. You will be responsible for any costs incurred.
> 
> To reduce costs, you can comment out some instances in `terraform/locals.tf`.

## Getting Started
```shell
# Initialize the environment, create admin user, API token, set up tfvars file
make setup

# Auth to GCP
gcloud auth login --update-adc

# Run terraform init and terraform apply
make tf-init
make tf-apply
```

## Available Make Commands

This project uses Docker Compose, managed via a `Makefile`, to simplify common operations.

```shell
cli               Exec into an already running LibreNMS container. Start the container if stopped.
debug             Launch docker-compose environment in attached mode.
destroy           Destroy all the docker containers and attached volumes. This will delete all data!!
destroy-all       DESTROY EVERYTHING: all docker containers and volumes and all Terraform resources.
help              Show this help message.
logs              Tail the logs of the compose environment.
restart           Restart docker containers.
setup             Initialize the environment, create admin user, API token, set up tfvars file.
start             Start the docker-compose environment in detached mode.
stop              Stop and bring down all the running containers started by compose.

# Terraform helpers
tf-init           Run terraform init.
tf-plan           Run terraform plan.
tf-apply          Run terraform apply.
tf-destroy        Run terraform destroy.

```
