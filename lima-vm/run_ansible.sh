#!/bin/bash
set -o nounset

VIRTUALENV_DIR="$HOME/env"

export ANSIBLE_PYTHON_INTERPRETER=$VIRTUALENV_DIR/bin/python
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"

# inside the VM this will always give the right value
current_ip="$(hostname -i | grep -o '[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+')"
ansible-playbook \
    --diff \
    --extra-vars "lima_kilo_docker_addr=$current_ip" \
    "$(dirname $0)/../playbooks/kind-install.yaml" \
    "$@"

