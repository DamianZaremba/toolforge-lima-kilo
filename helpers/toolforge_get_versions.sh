#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail


APT_PACKAGES=(
    "toolforge-webservice"
    "toolforge-jobs-framework-cli"
    "toolforge-builds-cli"
    "toolforge-cli"
    "python3-toolforge-weld"
)


HELM_CHARTS=(
    "jobs-api"
    "builds-api"
    "api-gateway"
    "builds-builder"
    "cert-manager"
    "envvars-admission"
    "envvars-api"
    "image-config"
    "kyverno"
    "volume-admission"
    "wmcs-metrics"
    "maintain-kubeusers"
)


show_package_version() {
    local package="${1?}"
    local cur_version
    cur_version=$(apt policy "$package" 2>/dev/null| grep '\*\*\*' | awk '{print $2}')
    echo "$package (package): $cur_version"
}


show_chart_version() {
    local chart="${1?}"
    local cur_version
    cur_version=$(helm list -A | grep "^$chart " | awk '{print $9}')
    echo "$chart (chart): $cur_version"
}

main() {
    local package \
        chart

    for package in "${APT_PACKAGES[@]}"; do
        show_package_version "$package"
    done

    for chart in "${HELM_CHARTS[@]}"; do
        show_chart_version "$chart"
    done
}


main "$@" | sort
