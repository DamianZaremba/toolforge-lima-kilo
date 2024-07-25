#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

~/toolforge-deploy/utils/toolforge_get_versions.sh
