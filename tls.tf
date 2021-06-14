
variable "ca_organization" {
  type = string
}

variable "ca_common_name" {
  type = string
}

output "ca_cert" {
  value = local.ca_cert
  sensitive = true
}

output "ca_filename" {
  value = local.ca_filename
}

locals {
  ca_cert = tls_self_signed_cert.ca.cert_pem
  ca_filename = "${replace(var.ca_common_name, " ", "_")}.crt"
}

# Root CA

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
    common_name = var.ca_common_name
    organization = var.ca_organization
  }
}

