#!/bin/bash

set -e
set -o pipefail

# foxtrot-ldap may need additional settings to go beyond this number
# for example, the maintain-kubeusers query returns 500 entries max
HOW_MANY="500"

START_UID="51000"
NAME_TEMPLATE="test-many"

COMMAND="kubectl -n foxtrot-ldap exec -i deployment/foxtrot-ldap -- container/utils/add-lima-kilo-tool-account.sh"


for i in $(seq 1 "${HOW_MANY}") ; do
    name="${NAME_TEMPLATE}-${i}"
    uid=$(( START_UID + i ))

    $COMMAND "$name" $uid $uid || true
done
