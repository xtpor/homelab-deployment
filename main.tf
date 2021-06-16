
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
    search_base_dn = module.service_openldap.search_base_dn
    bind_dn = module.service_openldap.service_dn
    bind_password = module.service_openldap.service_password
  }
}

# openldap

variable "ldap_organization" {
  type = string
}

variable "ldap_domain" {
  type = string
}

variable "ldap_host" {
  type = string
}

output "ldap_admin_password" {
  value = module.service_openldap.admin_password
  sensitive = true
}

output "ldap_config_password" {
  value = module.service_openldap.config_password
  sensitive = true
}

output "ldap_service_password" {
  value = module.service_openldap.service_password
  sensitive = true
}

output "ldap_host" {
  value = var.ldap_host
}

output "ldap_base_dn" {
  value = module.service_openldap.base_dn
}

# Container

module "service_openldap" {
  source = "./modules/service_openldap"

  docker_host = var.docker_host
  docker_network = docker_network.default.name
  name = "openldap"
  ldap_organization = var.ldap_organization
  ldap_domain = var.ldap_domain
  ldap_host = var.ldap_host
  tls_crt = module.tls_openldap.crt
  tls_key = module.tls_openldap.key
}

# TLS configurations

module "tls_openldap" {
  source = "./modules/cert"
  dns_names = ["openldap", var.ldap_host]
  ca_crt = module.ca.crt
  ca_key = module.ca.key
}


# postgres

variable "postgres_host" {
  type = string
}

output "postgres_root_password" {
  value = module.service_postgres.root_password
  sensitive = true
}

module "service_postgres" {
  source = "./modules/service_postgres"

  docker_host = var.docker_host
  docker_network = docker_network.default.name
  name = "postgres"
  tls_crt = module.tls_postgres.crt
  tls_key = module.tls_postgres.key
}


# TLS configurations

module "tls_postgres" {
  source = "./modules/cert"
  dns_names = [
    var.postgres_host,
    "postgres",
  ]
  ca_crt = module.ca.crt
  ca_key = module.ca.key
}
