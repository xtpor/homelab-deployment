
# Container

resource "docker_image" "phpldapadmin" {
  name = "osixia/phpldapadmin:0.9.0"
}

resource "docker_container" "phpldapadmin" {
  name = "phpldapadmin"
  image = docker_image.phpldapadmin.latest

  networks_advanced {
    name = docker_network.default.name
  }

  ports {
    internal = 80
    external = 8001
  }

  env = [
    "PHPLDAPADMIN_HTTPS=false",
    "PHPLDAPADMIN_LDAP_HOSTS=${docker_container.openldap.name}",
  ]
}
