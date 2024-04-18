#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CURDIR="$(realpath "$(dirname "$0")")"
REPO_DOTFILES="$CURDIR/lima-vm/dotfiles"
RECURSIVE="false"
COPY_SRC=""

help() {
    cat <<EOH
Usage: $0 [options]

This script will create, start, and configure a VM running lima-kilo.

Options:
  --recreate          If the VM already exists, it will be removed and created anew.
  --dotfiles [PATH]   Specify a path for copying dotfiles to the VM's home directory.
                      If the --dotfiles flag is not provided, it defaults to using the 
                      LIMA_KILO_DOTFILES environment variable, if set.

EOH
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --recreate)
                recreate="true"
                shift
                ;;
            --dotfiles)
                if [[ -n "${2:-}" && ! ${2:-} == "--"* ]]; then
                    if [[ -d "$2" ]]; then
                        COPY_SRC="$(realpath "$2")"
                    elif [[ -d "$REPO_DOTFILES/$2" ]]; then
                        COPY_SRC="$REPO_DOTFILES/$2"
                        RECURSIVE="true"
                    else
                        echo "Error: Directory not found: $2"
                        exit 1
                    fi
                    shift 2
                else
                    echo "Error: --dotfiles option requires a path."
                    exit 1
                fi
                ;;
            --help)
                help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                help
                exit 1
                ;;
        esac
    done

    if [[ "$COPY_SRC" == "" ]] && [[ "${LIMA_KILO_DOTFILES:-}" != "" ]]; then
        RECURSIVE="true"
        if [[ -d "$(realpath "$LIMA_KILO_DOTFILES")" ]]; then
            COPY_SRC="$(realpath "$LIMA_KILO_DOTFILES")"
        elif [[ -d "$REPO_DOTFILES/$LIMA_KILO_DOTFILES" ]]; then
            COPY_SRC="$REPO_DOTFILES/$LIMA_KILO_DOTFILES"
        else
            echo "Error: Unable to find dotfiles, directory not found: $LIMA_KILO_DOTFILES"
            echo "Provide a full path, or set LIMA_KILO_DOTFILES to one of the following:"
            ls "$REPO_DOTFILES"
            exit 1
        fi
    fi
}

copy_files() {
    local copy_src="${1?}"
    local guest_destination="lima-kilo:~" 

    if [[ -d "$copy_src" ]]; then
        echo "Copying contents of directory '$copy_src' to the home directory on the lima-kilo VM..."

        shopt -s dotglob

        for file in "$copy_src"/*; do
            if [[ -f "$file" ]]; then
                echo "Copying '$file'..."
                limactl copy "$file" "$guest_destination"
            fi
        done

        shopt -u dotglob
    elif [[ -f "$copy_src" ]]; then
        echo "Copying file '$copy_src' to the home directory on the lima-kilo VM..."
        limactl copy "$copy_src" "$guest_destination"
    else
        echo "Error: The specified source '$copy_src' is not valid."
        exit 1
    fi
}


copy_files_recursive() {
    local copy_src="${1?}"
    local guest_destination="lima-kilo:~/" 

    echo "Copying directory '$copy_src' to the home directory on the lima-kilo VM..."
    if [[ -d "$copy_src" ]]; then
        shopt -s dotglob
        for file in "$copy_src"/*; do
            echo "Copying '$file'..."
            limactl copy --recursive "$file" "$guest_destination"
        done
        shopt -u dotglob
    else
        limactl copy --recursive "$copy_src" "$guest_destination"
    fi
}

main() {
    local recreate="false"
	local response
	local extra_create_opts
	
    parse_args "$@"

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
    limactl shell lima-kilo -- sudo hostnamectl hostname lima-kilo
    limactl shell lima-kilo -- ./lima-vm/install.sh
    if [[ "$COPY_SRC" != "" ]]; then
        if [[ "$RECURSIVE" == "true" ]]; then
            copy_files_recursive "$COPY_SRC"
        else
            copy_files "$COPY_SRC"
        fi
    fi

    echo "########################################################"
    echo "Now you can start a shell in your new lima-kilo vm with:"
    echo "    limactl shell lima-kilo"
}


main "$@"
