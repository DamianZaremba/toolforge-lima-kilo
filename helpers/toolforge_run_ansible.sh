#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

~/lima-kilo/lima-vm/run_ansible.sh "$@"
