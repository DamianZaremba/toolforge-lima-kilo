#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

RED="\e[41m"
YELLOW="\e[43m"
ENDCOLOR="\e[0m"

TOOLFORGE_DEPLOY_REPO=~/toolforge-deploy
TOOLFORGE_PACKAGE_REGISTRY_DIR=~/.lima-kilo/installed_packages


APT_PACKAGES=(
    "python3-toolforge-weld"
    "toolforge-builds-cli"
    "toolforge-cli"
    "toolforge-envvars-cli"
    "toolforge-jobs-framework-cli"
    "toolforge-webservice"
)


HELM_CHARTS=(
    "api-gateway"
    "builds-api"
    "builds-builder"
    "cert-manager"
    "envvars-admission"
    "envvars-api"
    "image-config"
    "jobs-api"
    "kyverno"
    "maintain-kubeusers"
    "registry-admission"
    "volume-admission"
    "wmcs-metrics"
)

get_toolforge_deploy_version() {
    local component="${1?}"
    if [[ "$component" =~ (cert-manager|kyverno) ]]; then
        # it stores the version in the helmfile
        echo "$component-$(grep version "$TOOLFORGE_DEPLOY_REPO"/components/"$component"/helmfile.yaml | awk '{print $2}' | tail -n 1)"
        return 0
    elif [[ "$component" == "wmcs-metrics" ]]; then
        # naming does not match the component name
        echo "wmcs-k8s-metrics-$(grep chartVersion "$TOOLFORGE_DEPLOY_REPO"/components/wmcs-k8s-metrics/values/local.yaml | awk '{print $2}' | tail -n 1)"
        return 0
    fi

    echo "$component-$(grep chartVersion "$TOOLFORGE_DEPLOY_REPO"/components/"$component"/values/local.yaml* | awk '{print $2}')"
    return 0
}


show_package_version() {
    local package="${1?}"
    local cur_version \
        last_apt_history_entry \
        installed_mr

    cur_version=$(apt policy "$package" 2>/dev/null| grep '\*\*\*' | awk '{print $2}')
    last_apt_history_entry=$(grep "$package" /var/log/apt/history.log | grep "^Commandline" | tail -n 1 || :)
    if [[ "$last_apt_history_entry" == *_all.deb ]]; then
        installed_mr=$( \
            jq '.mr_number' 2>/dev/null < "$TOOLFORGE_PACKAGE_REGISTRY_DIR/$package" \
            || echo "mr not found in $TOOLFORGE_PACKAGE_REGISTRY_DIR/$package" \
        )
        cur_version="$YELLOW$cur_version (mr:$installed_mr)$ENDCOLOR"
    fi
    echo -e "$package (package): $cur_version"
}


show_chart_version() {
    local chart="${1?}"
    local cur_version
    local td_version
    cur_version=$(helm list -A | grep "^$chart " | awk '{print $9}')
    td_version=$(get_toolforge_deploy_version "$chart")
    if [[ "$chart" == "wmcs-metrics" ]]; then
        name="wmcs-k8s-metrics"
    else
        name="$chart"
    fi
    if [[ "$cur_version" =~ ^.*-dev-mr-(.*)$ ]]; then
        cur_version="$YELLOW$cur_version (mr:${BASH_REMATCH[1]})$ENDCOLOR"
    elif [[ "$cur_version" != "$td_version" ]]; then
        cur_version="$RED$cur_version$ENDCOLOR $YELLOW(toolforge-deploy has $td_version)$ENDCOLOR"
    fi
    echo -e "$name (chart $chart): $cur_version"
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
