Toolforge lima kilo
===================

This is a repository that contains logic to setup a fake Toolforge kubernetes
environment in a given machine.

A *L*ocal *K*ubernetes deployment to help develop some of the Toolforge
internal components.

How to use it
-------------

Make sure you have `ansible` installed on your machine.

To install the fake Toolforge:

```
user@debian:~/git/cloud/toolforge/lima-kilo $ ansible-playbook -KD playbooks/debian-kind-install.yaml
```

To uninstall the fake Toolforge (beware, really removes things):

```
user@debian:~/git/cloud/toolforge/lima-kilo $ ansible-playbook -KD playbooks/debian-kind-uninstall.yaml
```

Configuration
-------------

You can create a configuration file in `playbooks/vars/local.yaml` with any of the following options:

```yaml
# Set to false if you prefer to manage the kubectl binary installation on your own.
lima_kilo_manage_kubectl_installation: true

# Set to false if you prefer to manage the kind binary installation on your own.
lima_kilo_manage_kind_installation: true
lima_kilo_kind_binary_path: /usr/local/bin/kind
```

License
-------
[GPL-3.0](//www.gnu.org/copyleft/gpl.html "GPL-3.0")
