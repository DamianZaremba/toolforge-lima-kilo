# Based on https://github.com/lima-vm/lima/blob/master/examples/docker-rootful.yaml
images:
  # Try to use release-yyyyMMdd image if available. Note that release-yyyyMMdd will be removed after several months.
  - location: "https://cloud.debian.org/images/cloud/trixie/20261116-2664/debian-13-genericcloud-amd64-20261116-2664.qcow2"
    arch: "x86_64"
    digest: "sha512:37cb32b320820417eb04b335afcf489bfb4cecce4a957190d09cb2bffbe02b56a1cadd62d78c6ead92aa7839d5ea65e4260f994bbb4b54490df59fdf11ee1d97"
  - location: "https://cloud.debian.org/images/cloud/trixie/20261116-2664/debian-13-genericcloud-arm64-20261116-2664.qcow2"
    arch: "aarch64"
    digest: "sha512:ecbb14df864d2f8842539733c10d7251c58294f86b85a487b23b2c959a9b75f003df6b289deb20e1aee03ef65de2b1429818689e1fbc4b727d579c61b247fee9"
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
  - { location: "@@LIMA_KILO_DIR_PLACEHOLDER@@", mountPoint: "/mnt/lima-kilo", sshfs: { followSymlinks: true } }
  # If running manually (not using start-devenv.sh), replace this with your path to the toolforge repos, or delete
  - { location: "@@TOOLFORGE_REPOS_DIR_PLACEHOLDER@@", mountPoint: "/mnt/toolforge", sshfs: { followSymlinks: true } }

# containerd is managed by Docker, not by Lima, so the values are set to false here.
containerd:
  system: false
  user: false

ssh:
  # 0 lets Lima pick a free host port on each create; set LIMA_KILO_SSH_PORT (see start-devenv.sh) to pin it
  localPort: @@SSH_LOCAL_PORT_PLACEHOLDER@@

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
