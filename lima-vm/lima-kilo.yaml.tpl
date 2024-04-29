# Based on https://github.com/lima-vm/lima/blob/master/examples/docker-rootful.yaml
images:
  # Try to use release-yyyyMMdd image if available. Note that release-yyyyMMdd will be removed after several months.
  - location: "https://cloud.debian.org/images/cloud/bookworm/20231210-1591/debian-12-genericcloud-amd64-20231210-1591.qcow2"
    arch: "x86_64"
    digest: "sha512:7b7f4d34bba4a6a819dbd67ae338b46141646de7b18ae3818a7aa178d383bfbb3e9e0197c545bb2d5fd5be7f8e55a7d449b285983ae86a09a294124bb97d3d5f"
  - location: "https://cloud.debian.org/images/cloud/bookworm/20240701-1795/debian-12-genericcloud-arm64-20240701-1795.qcow2"
    arch: "aarch64"
    digest: "sha512:61304dda3043ef7457d79f96556074fea7d915216dac18307f2b429e2c54b73fd63cd256fd0e08d87b8e87f14f29d20008750ebdc47a8f2850f585e73d2a576f"
  # Fallback to the latest release image.
  # Hint: run `limactl prune` to invalidate the cache
  - location: "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
    arch: "x86_64"
  - location: "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2"
    arch: "aarch64"
memory: "8GiB"
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
        SocketUser=${LIMA_CIDATA_USER}
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
