
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.12.2"
    }

    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }

    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
  }
}

variable "docker_host" {
  type = string
}

provider "docker" {
  host = var.docker_host
}

# Common config for the docker host

resource "docker_network" "default" {
  name = "apps"
}
