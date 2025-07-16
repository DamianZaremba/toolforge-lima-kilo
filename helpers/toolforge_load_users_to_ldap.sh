#!/bin/bash

# NOTE:
# this script should help reloading foxtrot-ldap users after a lima-vm reboot
# given foxtrot-ldap doesn't have persistent storage, and restarting the foxtrot-ldap
# container will result in a cleanup of the LDAP tree

set -o errexit
set -o pipefail
set -o nounset
set -v

toolforge_run_ansible.sh -D --tags foxtrot_ldap "$@"
