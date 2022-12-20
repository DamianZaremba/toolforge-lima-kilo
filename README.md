= Toolforge lima kilo =

This is a repository that contains logic to setup a fake Toolforge kubernetes
environment in a given machine.

A *L*ocal *K*ubernetes deployment to help develop some of the Toolforge
internal components.

== How to use it ==

Make sure you have `ansible` installed on your machine.

To install the fake Toolforge:

```
user@debian:~/git/cloud/toolforge/lima-kilo $ ansible-playbook -KD playbooks/debian-kind-install.yaml
```

To uninstall the fake Toolforge (beware, really removes things):

```
user@debian:~/git/cloud/toolforge/lima-kilo $ ansible-playbook -KD playbooks/debian-kind-uninstall.yaml
```
