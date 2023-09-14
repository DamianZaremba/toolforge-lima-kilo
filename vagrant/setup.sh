#!/bin/bash
set -e

# Install general packages
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
	curl \
	git \
	jq \
	python3-distutils \
	python3-pip

# Configure locale if not already set
if ! grep -q "en_US.UTF-8" /etc/locale.gen; then
  echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
fi
