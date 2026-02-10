#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

/mnt/lima-kilo/lima-vm/run_ansible.sh "$@"
