# Lima Installation and Testing Guide

This is a troubleshooting guide with tips and tricks on running lima-kilo on lima-vm

You should have already followed the steps in the main [lima-kilo README](.../README.md)

1. You'll need to replace the placeholder for the lima-kilo directory mount:
   ```bash
      sed -e "s|@@LIMA_KILO_DIR_PLACEHOLDER@@|/path/to/lima-kilo|g" "lima-kilo.yaml.tpl" > "lima-kilo.yaml" 
   ```

2. You can manually create the VM with custom options:
   ```bash
      limactl create lima-kilo.yaml
   ```

3. Run the `install.sh` script, you can pass any extra parameters to it and they will be passed to ansible:

   ```bash
   ./install.sh # this will run ansible-playbook, any extra parameters will be passed to run_ansible.sh, see below for options
   ```

5. Make sure you can run a build successfully.

   ```bash
   $ become tf-test
   local.tf-test$ toolforge build start https://gitlab.wikimedia.org/toolforge-repos/wm-lol
   ````


If you want to only rerun the ansible playbooks, you can use the `run_ansible.sh` script:

   ```bash
   ./run_ansible.sh # it will forward any args to ansible-playbook
                    # like -e myvar=myvalue
                    # or --tag k8s,k9s
   ```
