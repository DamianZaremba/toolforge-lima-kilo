#!/bin/bash
set -e

# Install general packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
	curl \
	docker-compose \
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

# this will not be needed once https://gitlab.wikimedia.org/repos/cloud/toolforge/builds-cli/-/merge_requests/8 is deployed
sudo bash -c "cat >/etc/apt/sources.list.d/tekton.list<<EOR
deb [trusted=yes] http://apt.wikimedia.org/wikimedia buster-wikimedia thirdparty/tekton
EOR"

sudo apt update
sudo apt install -y toolforge-cli toolforge-builds-cli toolforge-jobs-framework-cli toolforge-envvars-cli toolforge-webservice

