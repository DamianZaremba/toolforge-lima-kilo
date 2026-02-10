#!/bin/bash

VIRTUALENV_DIR="$HOME/env"
LIMA_KILO_DIR="$(realpath "$(dirname "$0")"/..)"

export DEBIAN_FRONTEND=noninteractive

set -o nounset

# Python 3.11+ won't let you pip install stuff globally
sudo apt install \
  --yes \
  -o Dpkg::Options::="--force-confold" \
  python3-venv \
  moreutils \
  yq
python3 -m venv "$VIRTUALENV_DIR"
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"
pip3 install -r "${LIMA_KILO_DIR}/requirements.txt"

! [[ -e "${HOME}/lima-kilo" ]] && ln -s "$LIMA_KILO_DIR" "${HOME}/lima-kilo"
! [[ -e "${HOME}/bin" ]] && ln -s "/opt/bin" "${HOME}/bin"
! [[ -e "${HOME}/toolforge" ]] && [[ -e "/mnt/toolforge" ]] && ln -s "/mnt/toolforge" "${HOME}/toolforge"

RUN_ANSIBLE="$(dirname "$0")/run_ansible.sh"
env ANSIBLE_FORCE_COLOR=true "$RUN_ANSIBLE" "$@"
