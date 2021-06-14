
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
  value = random_password.ldap_admin.result
  sensitive = true
}

output "ldap_config_password" {
  value = random_password.ldap_config.result
  sensitive = true
}

output "ldap_serviceaccount_password" {
  value = local.ldap_serviceaccount_password
  sensitive = true
}

output "ldap_host" {
  value = var.ldap_host
}

output "ldap_base_dn" {
  value = local.ldap_base_dn
}

locals {
  ldap_base_dn = join(
    ",",
    [for s in split(".", var.ldap_domain) : "dc=${s}"]
  )
  ldap_user_base_dn = "ou=Users,${local.ldap_base_dn}"
  ldap_serviceaccount_dn = "cn=serviceaccount,${local.ldap_base_dn}"
  ldap_serviceaccount_password = random_password.ldap_serviceaccount.result

  container_openldap_name = "openldap"
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
  name = "osixia/openldap:1.5.0"
}

resource "docker_volume" "openldap_data" {
}

resource "docker_volume" "openldap_config" {
}

resource "docker_container" "openldap" {
  name = local.container_openldap_name
  image = docker_image.openldap.latest

  networks_advanced {
    name = docker_network.default.name
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
    content = module.tls_openldap.crt
    file = "/container/service/slapd/assets/certs/ldap.crt"
  }

  upload {
    content = module.tls_openldap.key
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
    command = "${path.module}/provisioners/setup-ldap.sh"
    environment = {
      URL = "ldaps://${var.ldap_host}"
      BIND_DN = "cn=admin,${local.ldap_base_dn}"
      BIND_PASSWORD = nonsensitive(random_password.ldap_admin.result)
      DATA = templatefile("${path.module}/templates/ldap-seed.tpl.ldif", {
        organization_dn = local.ldap_base_dn
      })
    }
  }
}

# TLS configurations

module "tls_openldap" {
  source = "./modules/cert"
  dns_names = [
    local.container_openldap_name,
    var.ldap_host,
  ]
  ca_crt = module.ca.crt
  ca_key = module.ca.key
}
