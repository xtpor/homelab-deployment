
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

variable "container_network" {
}

variable "container_name" {
}

variable "container_volume" {
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

resource "docker_image" "postgres" {
  name = "tintinho/postgres:13.3"
}

resource "docker_container" "postgres" {
  name = var.container_name
  image = docker_image.postgres.latest
  command = [
    "-c",
    "ssl=on",
    "-c",
    "ssl_cert_file=/var/lib/postgresql/server.crt",
    "-c",
    "ssl_key_file=/var/lib/postgresql/server.key",
  ]

  networks_advanced {
    name = var.container_network
  }

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name = var.container_volume
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
