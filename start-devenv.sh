#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CURDIR="$(realpath "$(dirname "$0")")"

help() {
    cat <<EOH
    Usage: $0 [--recreate]

    This will create, start and install a VM running lima-kilo.

    Options:
        --recreate
            If the VM already exists, will remove it and create it anew.
EOH
}

main() {
    local recreate="false"
    local response
    if [[ "${1:-}" == "--recreate" ]]; then
        recreate="true"
    fi
    local extra_create_opts

    command -v limactl >/dev/null || {
        echo "Limactl does not seem to be installed, you can install it from https://lima-vm.io/"
        exit 1
    }

    if limactl list | grep lima-kilo; then
        if [[ "$recreate" == "false" ]]; then
            echo "lima-kilo VM already exists, do you want to recreate it? [yN]"
            read response
            if [[ "$response" =~ ^[nN].* ]] || [[ "$response" == "" ]]; then
                echo "Aborting at user request"
                exit 1
            fi
        fi

        limactl stop -f lima-kilo || :
        limactl delete lima-kilo
    fi

    if [[ $(uname -m) == 'arm64' ]]; then
        extra_create_opts=(
            --vm-type=vz
            --rosetta
        )
    fi

    sed -e "s|@@LIMA_KILO_DIR_PLACEHOLDER@@|$CURDIR|g" "$CURDIR/lima-vm/lima-kilo.yaml.tpl" > "$CURDIR/lima-vm/lima-kilo.yaml"

    limactl create "${extra_create_opts[@]}" "$CURDIR/lima-vm/lima-kilo.yaml"
    limactl start lima-kilo
    # the hostname contains the `lima-` prefix by default, see https://github.com/lima-vm/lima/discussions/1634
    # override it to remove the duplicated `lima` keyword
    limactl shell lima-kilo -- sudo hostname lima-kilo
    limactl shell lima-kilo -- ./lima-vm/install.sh

    echo "########################################################"
    echo "Now you can start a shell in your new lima-kilo vm with:"
    echo "    limactl shell lima-kilo"
}


main "$@"
