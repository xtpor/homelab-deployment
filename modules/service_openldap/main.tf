
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

    null = {
      source = "hashicorp/null"
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


variable "ldap_organization" {
  type = string
}

variable "ldap_domain" {
  type = string
}

variable "ldap_base_dn" {
  type = string
}

variable "tls_crt" {
}

variable "tls_key" {
  sensitive = true
}

output "admin_dn" {
  value = "cn=admin,${var.ldap_base_dn}"
}

output "admin_password" {
  value = random_password.ldap_admin.result
  sensitive = true
}

output "config_password" {
  value = random_password.ldap_config.result
  sensitive = true
}

output "service_dn" {
  value = "cn=serviceaccount,${var.ldap_base_dn}"
}

output "service_password" {
  value = random_password.ldap_serviceaccount.result
  sensitive = true
}

output "search_base_dn" {
  value = "ou=Users,${var.ldap_base_dn}"
}

# Container

provider "docker" {
  host = var.docker_host
}

# Secrets

resource "random_password" "ldap_admin" {
  length = 20
  special = false
}

resource "random_password" "ldap_config" {
  length = 20
  special = false
}

resource "random_password" "ldap_serviceaccount" {
  length = 20
  special = false
}

# Container

resource "docker_image" "openldap" {
  name = "tintinho/openldap:1.5.0"
}

resource "docker_container" "openldap" {
  name = var.container_name
  image = docker_image.openldap.latest

  networks_advanced {
    name = var.container_network
  }

  ports {
    internal = 389
    external = 389
  }

  ports {
    internal = 636
    external = 636
  }

  volumes {
    container_path = "/data"
    volume_name = var.container_volume
  }

  upload {
    content = var.tls_crt
    file = "/container/service/slapd/assets/certs/ldap.crt"
  }

  upload {
    content = var.tls_key
    file = "/container/service/slapd/assets/certs/ldap.key"
  }

  env = [
    "LDAP_ORGANISATION=${var.ldap_organization}",
    "LDAP_BASE_DN=${var.ldap_base_dn}",
    "LDAP_DOMAIN=${var.ldap_domain}",
    "LDAP_ADMIN_PASSWORD=${random_password.ldap_admin.result}",
    "LDAP_CONFIG_PASSWORD=${random_password.ldap_config.result}",
    "LDAP_READONLY_USER=true",
    "LDAP_READONLY_USER_USERNAME=serviceaccount",
    "LDAP_READONLY_USER_PASSWORD=${random_password.ldap_serviceaccount.result}",
    "LDAP_TLS_VERIFY_CLIENT=never",
    "LDAP_TLS_CA_CRT_FILENAME=ldap.crt",
  ]
}
