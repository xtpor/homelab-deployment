
variable "ca_common_name" {
}

variable "ca_organization" {
}

variable "dns_zone" {
}

variable "dns_lab_domain" {
}

variable "ldap_organization" {
}

variable "digitalocean_api_token" {
  sensitive = true
}

variable "zerossl_api_key" {
  sensitive = true
}

output "host0_ip" {
  value = module.phase1.host0_ip
}

output "ldap_admin_password" {
  value = module.phase2.ldap_admin_password
  sensitive = true
}

output "postgres_root_password" {
  value = module.phase2.postgres_root_password
  sensitive = true
}

locals {
  ldap_host = "ldap.${var.dns_lab_domain}"
  postgres_host = "postgres.${var.dns_lab_domain}"
  pgadmin_host = "pgadmin.${var.dns_lab_domain}"

  ldap_domain = var.dns_lab_domain
  ldap_base_dn = join(",", [for s in split(".", local.ldap_domain) : "dc=${s}"])
}


module "phase1" {
  source = "./phases/phase1"

  digitalocean_api_token = var.digitalocean_api_token
  dns_zone = var.dns_zone
  dns_lab_domain = var.dns_lab_domain
  ca_common_name = var.ca_common_name
  ca_organization = var.ca_organization
}

module "phase2" {
  source = "./phases/phase2"

  ca_crt = module.phase1.ca_crt
  ca_key = module.phase1.ca_key
  host0_ip = module.phase1.host0_ip
  ldap_organization = var.ldap_organization
  ldap_domain = local.ldap_domain
  ldap_base_dn = local.ldap_base_dn
  ldap_host = local.ldap_host
  postgres_host = local.postgres_host
}

module "phase3" {
  source = "./phases/phase3"

  host0_ip = module.phase1.host0_ip
  host0_docker_network = module.phase2.host0_docker_network
  zerossl_api_key = var.zerossl_api_key
  ca_crt = module.phase1.ca_crt

  ldap_base_dn = local.ldap_base_dn
  ldap_admin_dn = module.phase2.ldap_admin_dn
  ldap_admin_password = module.phase2.ldap_admin_password
  ldap_service_dn = module.phase2.ldap_service_dn
  ldap_service_password = module.phase2.ldap_service_password
  ldap_host = local.ldap_host

  postgres_host = local.postgres_host
  postgres_root_password = module.phase2.postgres_root_password

  pgadmin_host = local.pgadmin_host
}
