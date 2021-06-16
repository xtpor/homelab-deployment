
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.12.2"
    }
  }
}

variable "docker_host" {
}

variable "docker_network" {
}

variable "name" {
}

variable "ldap_host" {
}

output "port" {
  value = 80
}

# Resources

provider "docker" {
  host = var.docker_host
}

resource "docker_image" "service" {
  name = "osixia/phpldapadmin:0.9.0"
}

resource "docker_container" "service" {
  name = var.name
  image = docker_image.service.latest

  networks_advanced {
    name = var.docker_network
  }

  # TODO: please remove this
  ports {
    internal = 80
    external = 8001
  }

  env = [
    "PHPLDAPADMIN_HTTPS=false",
    "PHPLDAPADMIN_LDAP_HOSTS=${var.ldap_host}",
  ]
}
