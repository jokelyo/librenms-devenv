# librenms-dev
Local dev instance of LibreNMS. Test the [LibreNMS Terraform provider](https://github.com/jokelyo/terraform-provider-librenms) with GCP environment setup.

## Requirements
* Docker
* Docker Compose
* Make
* Terraform (for GCP environment)
* Google Cloud SDK (`gcloud`) (for GCP environment)
* A Google Cloud account with billing enabled (for GCP environment)
* A Google Cloud project created (for GCP environment)

> [!WARNING]
> To prevent polling performance issues inside the librenms container, you should enable the `Use kernel networking for UDP` option in the Docker Desktop settings.
> Settings -> Resources -> Network -> Use kernel networking for UDP


## Available Make Commands

This project uses Docker Compose, managed via a `Makefile`, to simplify common operations.

```shell
cli               Exec into an already running LibreNMS container. Start the container if stopped.
debug             Launch docker-compose environment in attached mode.
destroy           Destroy all the docker containers and attached volumes. This will delete all data!!
help              Show this help message.
logs              Tail the logs of the compose environment.
restart           Restart docker containers.
start             Start the docker-compose environment in detached mode.
stop              Stop and bring down all the running containers started by compose.

```
