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

NOTE: It is a good practice to *uninstall* using the playbooks before updating to a newer git revision, that
way resources are smoothly cleaned up before new code potentially doesn't know how to handle them.

Configuration
-------------

You may create a configuration file in `~/.local/toolforge-lima-kilo/userconfig.yaml` with local options, such as:

```yaml
# Set to false if you prefer to manage the kubectl binary installation on your own.
lima_kilo_manage_kubectl_installation: true
lima_kilo_kubectl_binary_path: /usr/local/bin/kubectl

# Set to false if you prefer to manage the kind binary installation on your own.
lima_kilo_manage_kind_installation: true
lima_kilo_kind_binary_path: /usr/local/bin/kind

# You can use this to prevent apt from uninstalling your local packages in debian uninstall targets
lima_kilo_apt_uninstall: true

# Set to false to prevent managing a shortcut in /etc/hosts for kind.
lima_kilo_manage_etc_hosts_shortcut_for_kind: true
```
Hint: you may use this mechanism to override any other internal lima-kilo variable.

NOTE: in previous lima-kilo revisions, the config file was `~/.config/toolforge-lima-kilo-userconfig.yaml`.

License
-------
[GPL-3.0](//www.gnu.org/copyleft/gpl.html "GPL-3.0")
