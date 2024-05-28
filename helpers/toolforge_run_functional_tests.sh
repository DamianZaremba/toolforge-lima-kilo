#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail


if [[ "$*" =~ "-r" ]] || [[ "$*" =~ "--refetch-tests" ]]; then
    cd "$HOME"/toolforge-deploy
    git fetch --all 2>/dev/null
    git reset --hard FETCH_HEAD
    cd -
fi


"$HOME"/toolforge-deploy/utils/run_functional_tests.sh "$@"
