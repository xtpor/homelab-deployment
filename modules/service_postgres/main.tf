
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.12.2"
    }

    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

variable "docker_host" {
}

variable "docker_network" {
}

variable "name" {
}

variable "tls_crt" {
}

variable "tls_key" {
}

output "root_password" {
  value = random_password.postgres_root.result
  sensitive = true
}

# Secrets

resource "random_password" "postgres_root" {
  length = 20
  special = false
}

# Container

provider "docker" {
  host = var.docker_host
}

resource "docker_image" "postgres" {
  name = "postgres:13.3"
}

resource "docker_volume" "postgres_data" {
}

resource "docker_container" "postgres" {
  name = var.name
  image = docker_image.postgres.latest
  command = [
    "-c",
    "ssl=on",
    "-c",
    "ssl_cert_file=/var/lib/postgresql/server.crt",
    "-c",
    "ssl_key_file=/var/lib/postgresql/server.key",
  ]

  # Fixes the permission of the private key before starting the server
  entrypoint = ["/bin/sh", "/docker-entrypoint-new.sh"]

  upload {
    content = <<-EOT
    set -eu
    chmod 640 /var/lib/postgresql/server.key
    chown root:postgres /var/lib/postgresql/server.key
    exec /docker-entrypoint.sh "$@"
    EOT
    file = "/docker-entrypoint-new.sh"
  }

  networks_advanced {
    name = var.docker_network
  }

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name = docker_volume.postgres_data.name
  }

  upload {
    content = var.tls_crt
    file = "/var/lib/postgresql/server.crt"
  }

  upload {
    content = var.tls_key
    file = "/var/lib/postgresql/server.key"
  }

  env = [
    "POSTGRES_PASSWORD=${random_password.postgres_root.result}",
  ]
}
