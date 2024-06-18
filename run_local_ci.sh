#!/bin/sh

set -e

BASE_DIR=$(dirname "$(realpath -s "$0")")
CONTAINER="tox"
IMAGE_NAME="docker-registry.tools.wmflabs.org/cloud-cicd-py39bullseye-tox:latest"

exit_trap() {
  docker rm -f $CONTAINER
}

set -x
trap 'exit_trap' EXIT

set -x
docker run \
    --name "${CONTAINER}" \
    --volume "${BASE_DIR}":/src \
    "${IMAGE_NAME}" \
    /bin/sh -c -- cd /src ; tox
