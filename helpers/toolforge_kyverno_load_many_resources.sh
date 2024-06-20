#!/bin/bash

set -e
set -o pipefail

HOW_MANY="4000"
TEMPLATE_URL="https://gitlab.wikimedia.org/repos/cloud/toolforge/maintain-kubeusers/-/raw/main/maintain_kubeusers/resources/kyverno_pod_policy.yaml.tpl?ref_type=heads&inline=false"
TMP_DIR=$(mktemp --directory)
POLICY_TEMPLATE="${TMP_DIR}/policy_template.yaml"

BASE_NAMESPACE="tool-tf-test"
BASE_TOOL_DATA_DIR="/data/project/tf-test"
BASE_TOOL_UID="50001"

wget "${TEMPLATE_URL}" -O "${POLICY_TEMPLATE}"

for i in $(seq 1 "${HOW_MANY}") ; do
    ns="${BASE_NAMESPACE}-${i}"
    data_dir="${BASE_TOOL_DATA_DIR}${i}"
    tool_uid="${BASE_TOOL_UID}${i}"

    kubectl create namespace "${ns}" || true
    # shellcheck disable=SC2140
    sed -e "s@\${TOOL_DATA_DIR}@$data_dir@g" \
        -e "s@\${TOOL_UID}@$tool_uid@g" \
        -e "s@\${NAMESPACE}@$ns@g" "${POLICY_TEMPLATE}" | \
        kubectl -n "${ns}" apply -f -
done
