
variable "ca_organization" {
  type = string
}

variable "ca_common_name" {
  type = string
}

output "ca_filename" {
  value = "${replace(var.ca_common_name, " ", "_")}.crt"
}

output "ca_cert" {
  value = tls_self_signed_cert.ca.cert_pem
  sensitive = true
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

