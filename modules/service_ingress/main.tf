
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.12.2"
    }
  }
}

variable "docker_host" {
}

variable "container_network" {
}

variable "container_name" {
}

variable "container_volume" {
}

variable "rules" {
}

variable "zerossl_api_key" {
  sensitive = true
}


resource "docker_image" "caddy" {
  name = "tintinho/caddy:2.3.0-custom"
}

resource "docker_container" "ingress" {
  name = var.container_name
  image = docker_image.caddy.latest
  command = ["caddy", "run", "--config", "/etc/caddy/config.json"]

  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  upload {
    content = templatefile("${path.module}/caddyfile.tpl.json", {
      zerossl_api_key = var.zerossl_api_key
      entries = var.rules
    })
    file = "/etc/caddy/config.json"
  }

  volumes {
    volume_name = var.container_volume
    container_path = "/data"
  }

  networks_advanced {
    name = var.container_network
  }
}
