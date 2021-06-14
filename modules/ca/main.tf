
terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

variable "common_name" {
}

variable "organization" {
}

output "crt" {
  value = tls_self_signed_cert.ca.cert_pem
}

output "key" {
  value = tls_private_key.ca.private_key_pem
  sensitive = true
}

output "crt_filename" {
  value = "${replace(var.common_name, " ", "_")}.crt"
}

# Resources

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm = "RSA"
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate = true
  validity_period_hours = 24 * 365 * 10
  allowed_uses = [
    "digital_signature",
    "crl_signing",
    "cert_signing",
  ]

  subject {
    common_name = var.common_name
    organization = var.organization
  }
}

