#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

sudo docker compose -f "/srv/ops/harbor/harbor/docker-compose.yml" "$@"
