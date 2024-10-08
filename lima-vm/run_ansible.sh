#!/bin/bash
set -o nounset

VIRTUALENV_DIR="$HOME/env"

export ANSIBLE_PYTHON_INTERPRETER=$VIRTUALENV_DIR/bin/python
export ANSIBLE_CONFIG="$HOME/lima-kilo/ansible.cfg"
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"

ansible-playbook \
    --diff \
    "$HOME/lima-kilo/playbooks/kind-install.yaml" \
    "$@" \
| ts
