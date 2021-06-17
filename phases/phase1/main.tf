
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.9.0"
    }
  }
}

variable "dns_zone" {
}

variable "dns_lab_domain" {
}

variable "ca_common_name" {
}

variable "ca_organization" {
}

variable "digitalocean_api_token" {
  sensitive = true
}

output "host0_ip" {
  value = module.homelab_host0.ip
}

output "ca_crt" {
  value = module.ca.crt
}

output "ca_key" {
  value = module.ca.key
  sensitive = true
}

output "ca_filename" {
  value = module.ca.crt_filename
}



provider "digitalocean" {
  token = var.digitalocean_api_token
}

# Servers

data "digitalocean_ssh_keys" "keys" {
}

module "homelab_host0" {
  source = "../../modules/digitalocean_host"

  digitalocean_api_token = var.digitalocean_api_token
  name = "homelab-0"
  ssh_keys = [for s in data.digitalocean_ssh_keys.keys.ssh_keys : s.fingerprint]
}

# DNS records

locals {
  dns_lab_domain_relative = (
    var.dns_lab_domain == var.dns_zone
    ? "@"
    : trimsuffix(trimsuffix(var.dns_lab_domain, var.dns_zone), ".")
  )
}

resource "digitalocean_record" "ldap" {
  domain = var.dns_zone
  type   = "A"
  name   = "ldap.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "postgres" {
  domain = var.dns_zone
  type   = "A"
  name   = "postgres.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "pgadmin" {
  domain = var.dns_zone
  type   = "A"
  name   = "pgadmin.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "git" {
  domain = var.dns_zone
  type   = "A"
  name   = "git.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "ci" {
  domain = var.dns_zone
  type   = "A"
  name   = "ci.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "registry" {
  domain = var.dns_zone
  type   = "A"
  name   = "registry.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "wiki" {
  domain = var.dns_zone
  type   = "A"
  name   = "wiki.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "kanban" {
  domain = var.dns_zone
  type   = "A"
  name   = "kanban.${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

resource "digitalocean_record" "main" {
  domain = var.dns_zone
  type   = "A"
  name   = "${local.dns_lab_domain_relative}"
  value  = module.homelab_host0.ip
  ttl    = 300
}

# CA

module "ca" {
  source = "../../modules/ca"
  common_name = var.ca_common_name
  organization = var.ca_organization
}
