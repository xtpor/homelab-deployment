#!/bin/sh
set -eux

sudo apt update -y

sudo apt install -y \
  htop \
  git \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  zip \
  unzip \
  lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo systemctl start docker
