
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

variable "docker_network" {
}

variable "name" {
}


variable "ldap_organization" {
  type = string
}

variable "ldap_domain" {
  type = string
}

variable "ldap_host" {
  type = string
}

variable "tls_crt" {
}

variable "tls_key" {
  sensitive = true
}

output "admin_dn" {
  value = "cn=admin,${local.base_dn}"
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
  value = "cn=serviceaccount,${local.base_dn}"
}

output "service_password" {
  value = random_password.ldap_serviceaccount.result
  sensitive = true
}

output "search_base_dn" {
  value = "ou=Users,${local.base_dn}"
}

output "base_dn" {
  value = local.base_dn
}

# Container

provider "docker" {
  host = var.docker_host
}

locals {
  base_dn = join(",", [for s in split(".", var.ldap_domain) : "dc=${s}"])
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

resource "docker_image" "main" {
  name = "osixia/openldap:1.5.0"
}

resource "docker_volume" "openldap_data" {
}

resource "docker_volume" "openldap_config" {
}

resource "docker_container" "openldap" {
  name = var.name
  image = docker_image.main.latest

  networks_advanced {
    name = var.docker_network
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
    container_path = "/var/lib/ldap"
    volume_name = docker_volume.openldap_data.name
  }

  volumes {
    container_path = "/etc/ldap/slapd.d"
    volume_name = docker_volume.openldap_config.name
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

resource "null_resource" "openldap_seeding" {
  triggers = {
    volume_id = docker_volume.openldap_data.id,
  }
  depends_on = [docker_container.openldap]

  provisioner "local-exec" {
    command = "${path.module}/../../provisioners/setup-ldap.sh"
    environment = {
      URL = "ldaps://${var.ldap_host}"
      BIND_DN = "cn=admin,${local.base_dn}"
      BIND_PASSWORD = nonsensitive(random_password.ldap_admin.result)
      DATA = templatefile("${path.module}/../../templates/ldap-seed.tpl.ldif", {
        organization_dn = local.base_dn
      })
    }
  }
}

