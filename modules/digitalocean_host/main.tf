
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.9.0"
    }
  }
}

variable "digitalocean_api_token" {
  sensitive = true
}

variable "name" {
}

variable "ssh_keys" {
}

output "ip" {
  value = digitalocean_droplet.host.ipv4_address
}

resource "digitalocean_droplet" "host" {
  image  = "debian-10-x64"
  name   = var.name
  region = "sgp1"
  size   = "s-1vcpu-1gb"
  ssh_keys = var.ssh_keys
  user_data = file("${path.module}/debian-docker-cloudinit.sh")

  provisioner "local-exec" {
    command = "sh ${path.module}/provisioner.sh root@${digitalocean_droplet.host.ipv4_address}"
  }
}
