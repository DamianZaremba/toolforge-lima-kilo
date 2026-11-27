#!/bin/bash
# Routes a given IPv6 subnet to a given kind node over the docker network,
# so their global addresses are reachable, rather than having to rely on NAT.
set -o errexit
set -o nounset
set -o pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <node> <ipv6 subnet>" >&2
    exit 2
fi

readonly NODE=$1
readonly SUBNET=$2

if [[ ! "$NODE" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
    echo "Invalid node name: '$NODE'" >&2
    exit 2
fi

if [[ ! "$SUBNET" =~ ^[0-9a-fA-F:]*:[0-9a-fA-F:]*/[0-9]{1,3}$ ]] || ((${SUBNET#*/} > 128)); then
    echo "Invalid IPv6 subnet: '$SUBNET'" >&2
    exit 2
fi

apply_route() {
    local address
    address=$(
        docker inspect \
            --type container \
            --format '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}} {{end}}' \
            "$NODE" 2>/dev/null | awk '{print $1}'
    ) || true

    if [[ -z "$address" ]]; then
        echo "$NODE has no IPv6 address (yet), not routing $SUBNET"
        return
    fi

    if [[ ! "$address" =~ ^[0-9a-fA-F:]+$ ]]; then
        echo "$NODE has an unexpected IPv6 address '$address', not routing $SUBNET" >&2
        return
    fi

    ip -6 route replace "$SUBNET" via "$address"
    echo "Routed $SUBNET via $NODE ($address)"
}

apply_route

# The docker container addresses can change, so we re-apply this every time the container starts.
# The docker events stream exists when docker stops, systemd will then restart ud
docker events \
    --filter type=container \
    --filter event=start \
    --filter "container=$NODE" \
    --format '{{.Actor.Attributes.name}}' |
    while read -r name;
    do
        if [[ "$name" == "$NODE" ]]; then
            apply_route
        fi
    done
