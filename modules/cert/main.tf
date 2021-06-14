
terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

variable "dns_names" {
}

variable "ca_crt" {
}

variable "ca_key" {
}

output "crt" {
  value = tls_locally_signed_cert.server.cert_pem
}

output "key" {
  value = tls_private_key.server.private_key_pem
  sensitive = true
}

# Resource

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_cert_request" "server" {
  key_algorithm = "RSA"
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = var.dns_names[0]
  }

  dns_names = var.dns_names
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = var.ca_key
  ca_cert_pem        = var.ca_crt

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}
