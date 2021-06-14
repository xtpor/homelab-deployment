
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
    content = module.tls_postgres.crt
    file = "/var/lib/postgresql/server.crt"
  }

  upload {
    content = module.tls_postgres.key
    file = "/var/lib/postgresql/server.key"
  }

  env = [
    "POSTGRES_PASSWORD=${random_password.postgres_root.result}",
  ]
}

# TLS configurations

module "tls_postgres" {
  source = "./modules/cert"
  dns_names = [
    local.container_postgres_name,
    var.postgres_host,
  ]
  ca_crt = module.ca.crt
  ca_key = module.ca.key
}
