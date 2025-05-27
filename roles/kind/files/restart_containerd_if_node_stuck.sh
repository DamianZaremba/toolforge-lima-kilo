#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


main() {
    while ! ~/bin/kubectl get nodes toolforge-control-plane &>/dev/null; do
        echo "Waiting for k8s to be available..."
        sleep 5
    done
    while ! docker exec toolforge-control-plane "hostname" >/dev/null; do
        echo "Waiting for toolforge-control-plane container to be available..."
        sleep 5
    done

    while true; do
        if ! ~/bin/kubectl get nodes toolforge-control-plane | grep -q " Ready "; then
            echo "Node is not ready, restarting containerd..."
            docker exec toolforge-control-plane bash -c "systemctl restart containerd"
            echo "Containerd restarted, sleeping a bit to let it come up."
            sleep 30
        else
            echo "Node is ready, no action needed."
        fi

        sleep 5
    done
}


main "$@"
