#!/bin/bash
set -e

VIRTUALENV_DIR="$HOME/env"
LIMA_KILO_DIR="$(dirname $0)/.."

export ANSIBLE_PYTHON_INTERPRETER=$VIRTUALENV_DIR/bin/python
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"
cd  "$LIMA_KILO_DIR"
ansible-playbook -D playbooks/kind-install.yaml

