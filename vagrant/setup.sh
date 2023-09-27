#!/bin/bash
set -e

# Install general packages
sudo apt get update && sudo apt get upgrade -y
sudo apt get install -y \
	curl \
	git \
	jq \
	python3-distutils \
	python3-pip \
	python3-venv \
	vim

# configure toolforge apt repo
sudo bash -c "cat >/etc/apt/sources.list.d/toolforge.list<<EOR
deb [trusted=yes] https://deb-tools.wmcloud.org/repo bullseye-tools main
EOR"

# this wtill not be needed once https://gitlab.wikimedia.org/repos/cloud/toolforge/builds-cli/-/merge_requests/8 is deployed
sudo bash -c "cat >/etc/apt/sources.list.d/tekton.list<<EOR
deb [trusted=yes] http://apt.wikimedia.org/wikimedia buster-wikimedia thirdparty/tekton
EOR"

sudo apt update
sudo apt install -y toolforge-cli toolforge-builds-cli toolforge-jobs-framework-cli toolforge-envvars-cli toolforge-webservice

# Configure locale if not already set
if ! grep -q "en_US.UTF-8" /etc/locale.gen; then
  echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
fi
