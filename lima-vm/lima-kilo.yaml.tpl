# Based on https://github.com/lima-vm/lima/blob/master/examples/docker-rootful.yaml
images:
  # Try to use release-yyyyMMdd image if available. Note that release-yyyyMMdd will be removed after several months.
  - location: "https://cloud.debian.org/images/cloud/trixie/20250924-2245/debian-13-genericcloud-amd64-20250924-2245.qcow2"
    arch: "x86_64"
    digest: "sha512:25b430e6416b443620fc32975f40effe3d7ae6603060aa9563b80092f0b073734a35a8c56816ae4f4ea395d7e5599de7cba254f92a9465f6ce95b29a03a8e1f5"
  - location: "https://cloud.debian.org/images/cloud/trixie/20250924-2245/debian-13-genericcloud-arm64-20250924-2245.qcow2"
    arch: "aarch64"
    digest: "sha512:e23218e54163a0b4f88a80cdba5c5e84b1d43c19702644baac74f1904c327087032b0a9e77dcb7a4c50cf68850607caf3d3495ec9ca4d19887835dbc802723de"
  # Fallback to the latest release image.
  # Hint: run `limactl prune` to invalidate the cache
  - location: "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
    arch: "x86_64"
  - location: "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-arm64.qcow2"
    arch: "aarch64"
cpus: 16
memory: "16GiB"
disk: "50GiB"
mounts:
  # If running manually (not using start-devenv.sh), replace this with your path to the lima-kilo directory
  - location: "@@LIMA_KILO_DIR_PLACEHOLDER@@"

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
