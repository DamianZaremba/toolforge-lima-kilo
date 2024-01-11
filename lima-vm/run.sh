#!/bin/bash
set -e

VIRTUALENV_DIR="$HOME/env"

export ANSIBLE_PYTHON_INTERPRETER=$VIRTUALENV_DIR/bin/python
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"
ansible-playbook -KD playbooks/kind-install.yaml

