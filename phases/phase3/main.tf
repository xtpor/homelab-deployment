
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.12.2"
    }
  }
}


variable "host0_ip" {
}

variable "host0_docker_network" {
}

variable "zerossl_api_key" {
  sensitive = true
}

variable "ca_crt" {
}

variable "ldap_base_dn" {
}

variable "ldap_admin_dn" {
}

variable "ldap_admin_password" {
  sensitive = true
}

variable "ldap_service_dn" {
}

variable "ldap_service_password" {
  sensitive = true
}

variable "ldap_host" {
}

variable "postgres_host" {
}

variable "postgres_root_password" {
  sensitive = true
}

variable "pgadmin_host" {
}

locals {
  host0_docker_host = "ssh://root@${var.host0_ip}"
}

provider "docker" {
  host = local.host0_docker_host
}

# -

module "schema_openldap" {
  source = "../../modules/schema_openldap"

  hostname = var.ldap_host
  port = 636
  tls = true
  base_dn = var.ldap_base_dn
  bind_dn = var.ldap_admin_dn
  bind_password = var.ldap_admin_password
}

module "service_phpldapadmin" {
  source = "../../modules/service_phpldapadmin"

  docker_host = local.host0_docker_host
  container_network = var.host0_docker_network
  container_name = "phpldapadmin"
  ldap_host = "openldap"
}

resource "docker_volume" "ingress_data" {
}

module "service_ingress" {
  source = "../../modules/service_ingress"

  docker_host = local.host0_docker_host
  container_network = var.host0_docker_network
  container_volume = docker_volume.ingress_data.name
  container_name = "ingress"

  zerossl_api_key = var.zerossl_api_key
  rules = [
    { domain = var.ldap_host, gateway: "phpldapadmin:80" },
    { domain = var.pgadmin_host, gateway: "pgadmin4:80" },
  ]
}

module "service_pgadmin4" {
  source = "../../modules/service_pgadmin4"

  docker_host = local.host0_docker_host
  docker_network = var.host0_docker_network
  name = "pgadmin4"
  ldap = {
    hostname = var.ldap_host
    ca_crt = var.ca_crt
    search_base_dn = module.schema_openldap.search_base_dn
    bind_dn = var.ldap_service_dn
    bind_password = var.ldap_service_password
  }
}
