#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail


help() {
    cat <<EOH
    Usage $0 [-r|-h]

    Description:
        This restores all the components that have been modified, or out of sync with the toolforge-deploy repository under ~/toolforge-deploy

        It uses toolforge_get_versions.sh and toolforge_deploy

    Options:
        -h
            Show this help

        -r
            If passed, it will git fetch && git reset --hard FETCH_HEAD the toolforge-deploy repository getting the latest changes.
EOH
}


get_modified_k8s_components() {
    toolforge_get_versions.sh \
    | grep -e '\(mr:\|toolforge-deploy has\)' \
    | awk '{print $2}'
}

main() {
    if [[ "${1:-}" == "-h" ]]; then
        help
        exit 0
    fi
    if [[ "${1:-}" == "-r" ]]; then
        echo "Updating toolforge-deploy to latest"
        cd ~/toolforge-deploy
        git fetch --all && git reset --hard FETCH_HEAD
    fi
    for component in $(get_modified_k8s_components); do
        echo "### Restoring component $component"
        # the heredoc is to avoid it asking for confirmation
        toolforge_deploy "$component" restore <<<""
    done
}


main "$@"
