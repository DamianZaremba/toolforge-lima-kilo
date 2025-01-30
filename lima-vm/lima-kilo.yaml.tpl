# Based on https://github.com/lima-vm/lima/blob/master/examples/docker-rootful.yaml
images:
  # Try to use release-yyyyMMdd image if available. Note that release-yyyyMMdd will be removed after several months.
  - location: "https://cloud.debian.org/images/cloud/bookworm/20250316-2053/debian-12-genericcloud-amd64-20250316-2053.qcow2"
    arch: "x86_64"
    digest: "sha512:0ea74c246c5eb8c6eb5b8e3b8b5268b16a791dfbc8f0bca27d9d787a3f4c50a7830bfc690e6902dfe78031fb2b2c3892349990d6b26b13112252a81d6f20f792"
  - location: "https://cloud.debian.org/images/cloud/bookworm/20250316-2053/debian-12-genericcloud-arm64-20250316-2053.qcow2"
    arch: "aarch64"
    digest: "sha512:a6733f7f76ef62706e9e04dbad15d7ca251a2875d31025d9e8893391985b7e0610c96b6133ec5b2fa5fc4426bb3e6dcc91da77d0b3dc59bf4352e30625fc180d"
  # Fallback to the latest release image.
  # Hint: run `limactl prune` to invalidate the cache
  - location: "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
    arch: "x86_64"
  - location: "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2"
    arch: "aarch64"
cpus: 16
memory: "16GiB"
disk: "50GiB"
mounts:
  # If running manually (not using start-devenv.sh), replace this with your path to the lima-kilo directory
  - location: "@@LIMA_KILO_DIR_PLACEHOLDER@@"

# this helps sssd to don't choke on resolving the VM name
hostResolver:
  hosts:
    lima-kilo: 127.0.0.1
    # same as the toolforge api
    tf-test.local: 127.0.0.1
    tf-test2.local: 127.0.0.1

# containerd is managed by Docker, not by Lima, so the values are set to false here.
containerd:
  system: false
  user: false

portForwards:
  # Harbor
  - guestPort: 80
    hostPort: 8080

#@@ADDITIONAL_DISKS_PLACEHOLDER@@additionalDisks:
#@@ADDITIONAL_DISKS_PLACEHOLDER@@  - cache

provision:
  - mode: system
    script: |
      #!/bin/bash
      set -eux -o pipefail
      command -v docker >/dev/null 2>&1 && exit 0
      if [ ! -e /etc/systemd/system/docker.socket.d/override.conf ]; then
        mkdir -p /etc/systemd/system/docker.socket.d
        # Alternatively we could just add the user to the "docker" group, but that requires restarting the user session
        cat <<-EOF >/etc/systemd/system/docker.socket.d/override.conf
        [Socket]
        SocketUser={{.User}}
      EOF
      fi
      export DEBIAN_FRONTEND=noninteractive
      curl -fsSL https://get.docker.com | sh
probes:
  - script: |
      #!/bin/bash
      set -eux -o pipefail
      if ! timeout 30s bash -c "until command -v docker >/dev/null 2>&1; do sleep 3; done"; then
        echo >&2 "docker is not installed yet"
        exit 1
      fi
      if ! timeout 30s bash -c "until pgrep dockerd; do sleep 3; done"; then
        echo >&2 "dockerd is not running"
        exit 1
      fi
    hint: See "/var/log/cloud-init-output.log". in the guest
