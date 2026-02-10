#!/bin/bash
set -o nounset

######################################################################################
# Ansible can't handle the condensed tags syntax we want to use.
# convert --tags in the form ":tag4", "tag1:", "tag1:tag4", ----> "tag1,tag2,tag3,tag4"

ANSIBLE_ARGS=()
TAGS_ARG=""
TAGS=""
# Process arguments to expand tag ranges
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--tags)
            TAGS_ARG="$2"
            shift 2
            ;;
        -t*|--tags=*)
            TAGS_ARG="${1#*=}"
            shift
            ;;
        *)
            ANSIBLE_ARGS+=("$1")
            shift
            ;;
    esac
done

# Extract all tags
# shellcheck disable=SC2207
ALL_TAGS=( $(yq -r '.[0].roles[].tags' "/mnt/lima-kilo/playbooks/kind-install.yaml") )

find_index() {
    # Find index of a tag in ALL_TAGS
    for idx in "${!ALL_TAGS[@]}"; do
    [[ "${ALL_TAGS[$idx]}" == "$1" ]] && echo "$idx" && return
    done
    echo -1
}

expand_tag_range() {
    # tag1:tag4 --------> tag1,tag2,tag3,tag4
    if [[ "$TAGS_ARG" == *:* ]]; then
        IFS=":" read -r START_TAG END_TAG <<< "$TAGS_ARG"
        START_IDX=0
        END_IDX=$((${#ALL_TAGS[@]} - 1))
        [[ -n "$START_TAG" ]] && START_IDX=$(find_index "$START_TAG")
        [[ -n "$END_TAG" ]] && END_IDX=$(find_index "$END_TAG")
        TAGS_LIST=("${ALL_TAGS[@]:$START_IDX:$((END_IDX - START_IDX + 1))}")
        TAGS=$(IFS=","; echo "${TAGS_LIST[*]}")
    else
        IFS="," read -r -a TAGS_LIST <<< "$TAGS_ARG"
        TAGS=$(IFS=","; echo "${TAGS_LIST[*]}")
    fi

    [[ -n "${TAGS[*]}" ]] && ANSIBLE_ARGS+=("--tags" "${TAGS[*]}")
}

expand_tag_range
VIRTUALENV_DIR="$HOME/env"

export ANSIBLE_PYTHON_INTERPRETER=$VIRTUALENV_DIR/bin/python
export ANSIBLE_CONFIG="/mnt/lima-kilo/ansible.cfg"
# shellcheck disable=SC1091
source "$VIRTUALENV_DIR/bin/activate"

ansible-playbook \
    --diff \
    "/mnt/lima-kilo/playbooks/kind-install.yaml" \
    "${ANSIBLE_ARGS[@]}"
