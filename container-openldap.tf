
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
    content = tls_locally_signed_cert.openldap.cert_pem
    file = "/container/service/slapd/assets/certs/ldap.crt"
  }

  upload {
    content = tls_private_key.openldap.private_key_pem
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

resource "tls_private_key" "openldap" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_cert_request" "openldap" {
  key_algorithm = "RSA"
  private_key_pem = tls_private_key.openldap.private_key_pem

  subject {
    common_name = local.container_openldap_name
    organization = var.ca_organization
  }

  dns_names = [
    var.ldap_host,
  ]
}

resource "tls_locally_signed_cert" "openldap" {
  cert_request_pem   = tls_cert_request.openldap.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}
