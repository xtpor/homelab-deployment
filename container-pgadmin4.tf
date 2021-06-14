
output "pgadmin4_admin_password" {
  value = random_password.pgadmin4_admin.result
  sensitive = true
}

# Secrets

resource "random_password" "pgadmin4_admin" {
  length = 20
  special = false
}

# Container

resource "docker_image" "pgadmin4" {
  name = "dpage/pgadmin4:5.3"
}

resource "docker_container" "pgadmin4" {
  name = "pgadmin4"
  image = docker_image.pgadmin4.latest

  networks_advanced {
    name = docker_network.default.name
  }

  ports {
    internal = 80
    external = 8002
  }

  upload {
    content = local.ca_cert
    file = "/usr/local/share/ca-certificates/${local.ca_filename}"
  }

  env = [
    "PGADMIN_DEFAULT_EMAIL=admin@example.com",
    "PGADMIN_DEFAULT_PASSWORD=${random_password.pgadmin4_admin.result}",
    "PGADMIN_CONFIG_AUTHENTICATION_SOURCES=['ldap', 'internal']",
    "PGADMIN_CONFIG_LDAP_AUTO_CREATE_USER=True",
    "PGADMIN_CONFIG_LDAP_SERVER_URI='ldaps://${docker_container.openldap.name}'",
    "PGADMIN_CONFIG_LDAP_CA_CERT_FILE='/usr/local/share/ca-certificates/${local.ca_filename}'",
    "PGADMIN_CONFIG_LDAP_USERNAME_ATTRIBUTE='uid'",
    "PGADMIN_CONFIG_LDAP_SEARCH_BASE_DN='${local.ldap_user_base_dn}'",
    "PGADMIN_CONFIG_LDAP_BIND_USER='${local.ldap_serviceaccount_dn}'",
    "PGADMIN_CONFIG_LDAP_BIND_PASSWORD='${local.ldap_serviceaccount_password}'",
  ]
}
