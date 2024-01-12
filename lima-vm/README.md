# Lima Installation and Testing Guide

This is a basic guide on how to install and test on Lima.

## Installation

1. Install Lima by following the instructions provided in the [official Lima-VM documentation](https://github.com/lima-vm/lima).

On Mac, it can be installed using `brew`. Otherwise, you need to clone the repo and install the binary from the [releases](https://github.com/lima-vm/lima/releases) or the build source with `make`.

## Testing

1. Create a new VM from the `bookworm.yaml` template:

   ```bash
   limactl start bookworm.yaml
   ```

2. Start the VM:

   ```bash
   limactl start bookworm
   ```

3. Get a shell in the VM:

   ```bash
   limactl shell bookworm
   ```

4. Run the `install.sh` script:

   ```bash
   ./install.sh # this will run ansbile-playbook
   ```

5. Make sure you can run a build successfully.

   ```bash
   $ sudo -i -u toolsbeta.tf-test
   toolsbeta.tf-test$ toolforge build start https://gitlab.wikimedia.org/toolforge-repos/wm-lol
   ````


If you want to rerun the ansible playbooks, you can use the `run_ansible.sh` script:

   ```bash
   ./run_ansible.sh # it will forward any args to ansible-playbook
                    # like -e myvar=myvalue
                    # or --tag k8s,k9s
   ```