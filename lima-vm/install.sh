#!/bin/bash

# NOTE: Edit LIMA_KILO_SOURCE_DIR to point to your lima-kilo folder
LIMA_KILO_SOURCE_DIR="$(dirname 0)/.."
VIRTUALENV_DIR="$HOME/env"
LIMA_KILO_DIR="$HOME/.toolforge-lima-kilo"
HARBOR_IP="172.19.0.1"
API_GATEWAY_IP=$HARBOR_IP

export DEBIAN_FRONTEND=noninteractive

set -e

cd $LIMA_KILO_SOURCE_DIR
# Python 3.11+ won't let you pip install stuff globally
sudo apt install \
  --yes \
  -o Dpkg::Options::="--force-confold" \
  python3.11-venv
python3 -m venv "$VIRTUALENV_DIR"
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"
pip3 install -r requirements.txt

{
  # so the base user can use kubectl and others
  echo "export PATH=$PATH:$LIMA_KILO_DIR/bin:$HOME/.local.bin"
  # if you want to deploy builds-* component from source, so it uses the right harbor ip
  echo "export HARBOR_IP=$HARBOR_IP"
} >> ~/.bashrc

# so the toolforge clis can reach the local api-gateway
sudo mkdir -p /etc/toolforge
sudo bash -c "cat >/etc/toolforge/common.yaml <<EOC
api_gateway:
  url: https://$API_GATEWAY_IP:30003
EOC
"

# add lima-vm specifics
mkdir -p "$LIMA_KILO_DIR"
cat >"$LIMA_KILO_DIR/userconfig.yaml"<<EOAC
lima_kilo_docker_addr: $HARBOR_IP
EOAC

# instal k9s for everyone in the VM
curl -L https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz | sudo tar xvzf - -C /usr/local/bin k9s