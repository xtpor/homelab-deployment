
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

variable "ldap" {
  type = object({
    hostname = string,
    ca_crt = string,
    search_base_dn = string,
    bind_dn = string,
    bind_password = string,
  })
}

output "admin_password" {
  value = random_password.admin.result
  sensitive = true
}

# Secrets

resource "random_password" "admin" {
  length = 20
  special = false
}

# Container

provider "docker" {
  host = var.docker_host
}

resource "docker_image" "main" {
  name = "dpage/pgadmin4:5.3"
}

resource "docker_container" "main" {
  name = var.name
  image = docker_image.main.latest

  networks_advanced {
    name = var.docker_network
  }

  # TODO: put this behind an ingress
  ports {
    internal = 80
    external = 8002
  }

  upload {
    content = var.ldap.ca_crt
    file = "/usr/local/share/ca-certificates/ldap_ca.crt"
  }

  env = [
    "PGADMIN_DEFAULT_EMAIL=admin@example.com",
    "PGADMIN_DEFAULT_PASSWORD=${random_password.admin.result}",
    "PGADMIN_CONFIG_AUTHENTICATION_SOURCES=['ldap', 'internal']",
    "PGADMIN_CONFIG_LDAP_AUTO_CREATE_USER=True",
    "PGADMIN_CONFIG_LDAP_SERVER_URI='ldaps://${var.ldap.hostname}'",
    "PGADMIN_CONFIG_LDAP_CA_CERT_FILE='/usr/local/share/ca-certificates/ldap_ca.crt'",
    "PGADMIN_CONFIG_LDAP_USERNAME_ATTRIBUTE='uid'",
    "PGADMIN_CONFIG_LDAP_SEARCH_BASE_DN='${var.ldap.search_base_dn}'",
    "PGADMIN_CONFIG_LDAP_BIND_USER='${var.ldap.bind_dn}'",
    "PGADMIN_CONFIG_LDAP_BIND_PASSWORD='${var.ldap.bind_password}'",
  ]
}
