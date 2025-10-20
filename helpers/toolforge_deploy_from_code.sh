#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail


TOOLFORGE_CODE_DIR="$HOME/toolforge"

help() {
    cat <<EOH
    Usage $0 <component|path_to_component>

    Note that it requires the component name to be the same as the directory it's cloned in, otherwise it will not
    work correctly (the image name will not be correct, etc.).

    Arguments
        component
            If a component name is passed, it will try to find the path to it's codebase under the
            $TOOLFORGE_CODE_DIR directory.

        path_to_component
            If a path is passed, it will expect it to be the root for the git directory for the component
            to deploy.
EOH
}

main() {
    if [[ "${1:-}" =~ ^-h|--help$ ]]; then
        help
        exit 0
    fi

    local component="${1?No component passed}"
    local component_git_dir
    if ! [[ -d "$component/.git" ]]; then
        echo "Auto-discovering the component code dir under $TOOLFORGE_CODE_DIR"
        # using timeout to avoid hanging, and using maxdepth so it does not got through venvs and such
        # tweak as needed
        component_git_dir="$( \
            timeout 10 \
                find "$TOOLFORGE_CODE_DIR" \
                    -maxdepth 4 \
                    -type d \
                    -path "*/$component/.git" \
            | head -n 1 \
        )"
        if [[ "$component_git_dir" == "" ]]; then
            echo "Unable to find the path to the component '$component' codebase under"\
                "'$TOOLFORGE_CODE_DIR', did you enable mounting the toolforge repos in lima-kilo?"
            exit 1
        fi
    else
        component_git_dir="$component/.git"
        component="$(basename "${PWD%/*}")"
    fi
    pushd "$component_git_dir/.."
    docker buildx build --target image -f .pipeline/blubber.yaml -t "toolsbeta-harbor.wmcloud.org/toolforge/$component:dev" .
    kind load docker-image "toolsbeta-harbor.wmcloud.org/toolforge/$component:dev" -n toolforge
    # the heredoc is to avoid interactive helm
    ./deploy.sh local <<<""
    popd
}


main "$@"
