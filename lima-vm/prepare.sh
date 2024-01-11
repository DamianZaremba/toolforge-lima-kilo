#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Install general packages
sudo apt update \
	&& sudo apt upgrade \
		--yes \
		-o Dpkg::Options::="--force-confdef" \
		-o Dpkg::Options::="--force-confold"
sudo apt install \
	--yes \
	-o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
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

sudo apt update
sudo apt install -y toolforge-cli toolforge-builds-cli toolforge-jobs-framework-cli toolforge-envvars-cli toolforge-webservice

