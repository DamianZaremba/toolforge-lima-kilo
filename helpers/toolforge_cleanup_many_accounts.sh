#!/bin/bash

set -v
set -e
set -o pipefail

NAME_TEMPLATE="test-many"

# restart foxtrot-ldap, so it looses the LDAP accounts (has no persistent storage)
kubectl -n foxtrot-ldap rollout restart deployment/foxtrot-ldap

# cleanup namespaces
# shellcheck disable=SC2046
kubectl delete namespace --wait=false --force=true $(kubectl get namespaces --no-headers=true | grep "tool-${NAME_TEMPLATE}" | awk -F' ' '{print $1}') || true

# cleanup directories
sudo rm -rf /data/project/${NAME_TEMPLATE}-*
