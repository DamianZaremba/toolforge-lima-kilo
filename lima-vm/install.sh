#!/bin/bash

# NOTE: Edit LIMA_KILO_SOURCE_DIR to point to your lima-kilo folder
LIMA_KILO_SOURCE_DIR="$(dirname 0)/.."
VIRTUALENV_DIR="$HOME/env"

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

"$(dirname $0)/run_ansible.sh"