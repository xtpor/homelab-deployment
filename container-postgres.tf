
variable "postgres_host" {
  type = string
}

output "postgres_root_password" {
  value = random_password.postgres_root.result
  sensitive = true
}

locals {
  container_postgres_name = "postgres"
}

# Secrets

resource "random_password" "postgres_root" {
  length = 20
  special = false
}

# Container

resource "docker_image" "postgres" {
  name = "postgres:13.3"
}

resource "docker_volume" "postgres_data" {
}

resource "docker_container" "postgres" {
  name = local.container_postgres_name
  image = docker_image.postgres.latest
  command = [
    "-c",
    "ssl=on",
    "-c",
    "ssl_cert_file=/var/lib/postgresql/server.crt",
    "-c",
    "ssl_key_file=/var/lib/postgresql/server.key",
  ]

  # Fixes the permission of the private key before starting the server
  entrypoint = ["/bin/sh", "/docker-entrypoint-new.sh"]

  upload {
    content = <<-EOT
    set -eu
    chmod 640 /var/lib/postgresql/server.key
    chown root:postgres /var/lib/postgresql/server.key
    exec /docker-entrypoint.sh "$@"
    EOT
    file = "/docker-entrypoint-new.sh"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name = docker_volume.postgres_data.name
  }

  upload {
    content = tls_locally_signed_cert.postgres.cert_pem
    file = "/var/lib/postgresql/server.crt"
  }

  upload {
    content = tls_private_key.postgres.private_key_pem
    file = "/var/lib/postgresql/server.key"
  }

  env = [
    "POSTGRES_PASSWORD=${random_password.postgres_root.result}",
  ]
}

# TLS configurations

resource "tls_private_key" "postgres" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_cert_request" "postgres" {
  key_algorithm = "RSA"
  private_key_pem = tls_private_key.postgres.private_key_pem

  subject {
    common_name = local.container_postgres_name
    organization = var.ca_organization
  }

  dns_names = [
    var.postgres_host,
  ]
}

resource "tls_locally_signed_cert" "postgres" {
  cert_request_pem   = tls_cert_request.postgres.cert_request_pem
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
