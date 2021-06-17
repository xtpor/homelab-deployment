
terraform {
  required_providers {
    ldap = {
      source = "elastic-infra/ldap"
      version = "2.0.0"
    }
  }
}

variable "hostname" {
}

variable "port" {
}

variable "tls" {
}

variable "base_dn" {
}

variable "bind_dn" {
}

variable "bind_password" {
}

output "search_base_dn" {
  value = ldap_object.users.dn
}


provider "ldap" {
  ldap_host = var.hostname
  ldap_port = var.port
  tls = var.tls
  tls_insecure = true
  bind_user = var.bind_dn
  bind_password = var.bind_password
}

resource "ldap_object" "users" {
  dn = "ou=Users,${var.base_dn}"

  object_classes = ["organizationalUnit"]

  attributes = [
    { description = "Gruop of users" },
  ]
}

resource "ldap_object" "testuser1" {
  dn = "uid=testuser1,${ldap_object.users.dn}"

  object_classes = ["inetOrgPerson"]

  attributes = [
    { cn = "Test User1" },
    { sn = "Test" },
    { userPassword = "testpassword1" },
    { mail = "testuser1@example.com" },
  ]
}

resource "ldap_object" "testuser2" {
  dn = "uid=testuser2,${ldap_object.users.dn}"

  object_classes = ["inetOrgPerson"]

  attributes = [
    { cn = "Test User2" },
    { sn = "Test" },
    { userPassword = "testpassword2" },
    { mail = "testuser2@example.com" },
  ]
}

resource "ldap_object" "testuser3" {
  dn = "uid=testuser3,${ldap_object.users.dn}"

  object_classes = ["inetOrgPerson"]

  attributes = [
    { cn = "Test User3" },
    { sn = "Test" },
    { userPassword = "testpassword3" },
    { mail = "testuser3@example.com" },
  ]
}
