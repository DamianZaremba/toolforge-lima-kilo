#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CURDIR="$(realpath "$(dirname "$0")")"
REPO_DOTFILES="$CURDIR/lima-vm/dotfiles"
RECURSIVE="false"
COPY_SRC=""
NAME="lima-kilo"

help() {
    cat <<EOH
Usage: $0 [options] -- [extra_args]

This script will create, start, and configure a VM running lima-kilo.

Options:
  --name [NAME]        Specify a name for the VM. Defaults to "lima-kilo".
  --recreate           If the VM already exists, it will be removed and created anew.
  --dotfiles [PATH]    Specify a path for copying dotfiles to the VM's home directory.
                       If the --dotfiles flag is not provided, it defaults to using the
                       LIMA_KILO_DOTFILES environment variable, if set.

Extra args:
    These will be passed through to ansible, some useful ones are:
    -e EXTRA_VARS, --extra-vars EXTRA_VARS
        set additional variables as key=value or YAML/JSON, if filename prepend with @. This argument may be specified
        multiple times.
    -t TAGS, --tags TAGS
        only run plays and tasks tagged with these values. This argument may be specified multiple times.
    -v, --verbose
        Causes Ansible to print more debug messages. Adding multiple -v will increase the verbosity, the builtin
        plugins currently evaluate up to -vvvvvv. A reasonable level to start is -vvv, connection debugging might
        require -vvvv. This argument may be specified multiple times.
    For others check ansible-playbook --help

EOH
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
                if [[ -n "${2:-}" && ! ${2:-} == "--"* ]]; then
                    NAME="$2"
                    shift 2
                else
                    echo "Error: --name option requires an argument."
                    exit 1
                fi
                ;;
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
            --)
                shift
                ansible_args=("$@")
                shift $#
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
    local guest_destination="${NAME}:~"

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
    local guest_destination="${NAME}:~"

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
    declare -a ansible_args

    parse_args "$@"

    command -v limactl >/dev/null || {
        echo "Limactl does not seem to be installed, you can install it from https://lima-vm.io/"
        exit 1
    }

    if limactl list | grep "$NAME"; then
        if [[ "$recreate" == "false" ]]; then
            echo "$NAME VM already exists, do you want to recreate it? [yN]"
            read -r response
            if [[ "$response" =~ ^[nN].* ]] || [[ "$response" == "" ]]; then
                echo "Aborting at user request"
                exit 1
            fi
        fi

        limactl stop -f "$NAME" || :
        limactl delete "$NAME"
    fi

    if [[ $(uname -m) == 'arm64' ]]; then
        extra_create_opts=(
            --vm-type=vz
            --rosetta
        )
    fi

    sed -e "s|@@LIMA_KILO_DIR_PLACEHOLDER@@|$CURDIR|g" "$CURDIR/lima-vm/lima-kilo.yaml.tpl" > "$CURDIR/lima-vm/lima-kilo.yaml"

    limactl create --name "$NAME" "${extra_create_opts[@]}" "$CURDIR/lima-vm/lima-kilo.yaml"
    limactl start "$NAME"
    # the hostname contains the `lima-` prefix by default, see https://github.com/lima-vm/lima/discussions/1634
    # override it to remove the duplicated `lima` keyword
    limactl shell "$NAME" -- sudo hostnamectl hostname "$NAME"
    limactl shell "$NAME" -- ./lima-vm/install.sh "${ansible_args[@]+"${ansible_args[@]}"}"
    if [[ "$COPY_SRC" != "" ]]; then
        if [[ "$RECURSIVE" == "true" ]]; then
            copy_files_recursive "$COPY_SRC"
        else
            copy_files "$COPY_SRC"
        fi
    fi

    echo "########################################################"
    echo "Now you can start a shell in your new $NAME VM with:"
    echo "    limactl shell $NAME"
}


main "$@"
