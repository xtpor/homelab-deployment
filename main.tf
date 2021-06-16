
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


# TLS related

variable "ca_organization" {
  type = string
}

variable "ca_common_name" {
  type = string
}

output "ca_cert" {
  value = module.ca.crt
  sensitive = true
}

output "ca_filename" {
  value = module.ca.crt_filename
}

# Root CA

module "ca" {
  source = "./modules/ca"
  common_name = var.ca_common_name
  organization = var.ca_organization
}

# Services

# phpldapadmin

module "service_phpldapadmin" {
  source = "./modules/service_phpldapadmin"

  docker_host = var.docker_host
  docker_network = docker_network.default.name
  name = "phpldapadmin"
  ldap_host = "openldap"
}

# pgadmin4

output "pgadmin4_admin_password" {
  value = module.service_pgadmin4.admin_password
  sensitive = true
}

module "service_pgadmin4" {
  source = "./modules/service_pgadmin4"

  docker_host = var.docker_host
  docker_network = docker_network.default.name
  name = "pgadmin4"
  ldap = {
    hostname = var.ldap_host
    ca_crt = module.ca.crt
    search_base_dn = local.ldap_user_base_dn
    bind_dn = local.ldap_serviceaccount_dn
    bind_password = local.ldap_serviceaccount_password
  }
}
