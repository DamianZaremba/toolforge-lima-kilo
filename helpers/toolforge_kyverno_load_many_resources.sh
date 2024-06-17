#!/bin/bash

set -e
set -o pipefail

HOW_MANY="4000"
TEMPLATE_URL="https://gitlab.wikimedia.org/repos/cloud/toolforge/maintain-kubeusers/-/raw/main/maintain_kubeusers/resources/kyverno_pod_policy.yaml.tpl?ref_type=heads&inline=false"
TMP_DIR=$(mktemp --directory)
POLICY_TEMPLATE="${TMP_DIR}/policy_template.yaml"
POLICY_BASE="${TMP_DIR}/policy_base.yaml"

NAMESPACE="tool-tf-test"
TOOL_DATA_DIR="/data/project/tf-test"
TOOL_UID="50001"
NAME="toolforge-kyverno-pod-policy"

wget "${TEMPLATE_URL}" -O "${POLICY_TEMPLATE}"

sed -e "s@\${TOOL_DATA_DIR}@$TOOL_DATA_DIR@g" \
    -e "s@\${NAMESPACE}@$NAMESPACE@g" \
    -e "s@\${TOOL_UID}@$TOOL_UID@g" "${POLICY_TEMPLATE}" > "${POLICY_BASE}"

kubectl delete namespace "${NAMESPACE}" || true
kubectl create namespace "${NAMESPACE}" || true

for i in $(seq 1 "${HOW_MANY}") ; do
    # shellcheck disable=SC2140
    sed -e s@"name: \"${NAME}\""@"name: \"${NAME}-${i}\""@g "${POLICY_BASE}" | \
        kubectl -n "${NAMESPACE}" apply -f -
done
