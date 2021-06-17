
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.12.2"
    }
  }
}

# Inputs, Outputs & Locals

variable "ca_crt" {
}

variable "ca_key" {
  sensitive = true
}

variable "host0_ip" {
}

variable "ldap_organization" {
}

variable "ldap_domain" {
}

variable "ldap_base_dn" {
}

variable "ldap_host" {
}

variable "postgres_host" {
}

output "host0_docker_network" {
  value = docker_network.default.name
}

output "ldap_admin_dn" {
  value = module.service_openldap.admin_dn
}

output "ldap_admin_password" {
  value = module.service_openldap.admin_password
  sensitive = true
}

output "ldap_config_dn" {
  value = module.service_openldap.config_dn
}

output "ldap_config_password" {
  value = module.service_openldap.config_password
  sensitive = true
}

output "ldap_service_dn" {
  value = module.service_openldap.service_dn
}

output "ldap_service_password" {
  value = module.service_openldap.service_password
  sensitive = true
}

output "postgres_root_password" {
  value = module.service_postgres.root_password
  sensitive = true
}

locals {
  host0_docker_host = "ssh://root@${var.host0_ip}"
}

# Resources

provider "docker" {
  host = local.host0_docker_host
}

resource "docker_network" "default" {
  name = "app"
}

resource "docker_volume" "openldap_database" {
}


module "service_openldap" {
  source = "../../modules/service_openldap"

  docker_host = local.host0_docker_host
  container_network = docker_network.default.name
  container_name = "openldap"
  container_volume = docker_volume.openldap_database.name

  ldap_organization = var.ldap_organization
  ldap_domain = var.ldap_domain
  ldap_base_dn = var.ldap_base_dn
  tls_crt = module.tls_openldap.crt
  tls_key = module.tls_openldap.key
}

module "tls_openldap" {
  source = "../../modules/cert"
  dns_names = ["openldap", var.ldap_host]
  ca_crt = var.ca_crt
  ca_key = var.ca_key
}


resource "docker_volume" "postgres_database" {
}

module "service_postgres" {
  source = "../../modules/service_postgres"

  docker_host = local.host0_docker_host
  container_network = docker_network.default.name
  container_name = "postgres"
  container_volume = docker_volume.postgres_database.name

  tls_crt = module.tls_postgres.crt
  tls_key = module.tls_postgres.key
}

module "tls_postgres" {
  source = "../../modules/cert"
  dns_names = ["postgres", var.postgres_host]
  ca_crt = var.ca_crt
  ca_key = var.ca_key
}
