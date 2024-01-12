Toolforge lima kilo
===================

This is a repository that contains logic to setup a fake Toolforge kubernetes
environment in a given machine.

A *L*ocal *K*ubernetes deployment to help develop some of the Toolforge
internal components.

It is highly recommended to run this inside a virtual machine, there's Vagrant and a LimaVM documentation and setup if you don't want to do it by hand.

How to use it
-------------

**Using Vagrant:**
See detailed instructions here: [Vagrant README](./vagrant/README.md)

**Using LimaVM:**
See detailed instructions here: [LimaVM README](./lima-vm/README.md)

Configuration
-------------

To override any of the default values for the configuration, you can override any variable using the `-e` option to ansible, for example `-e lima_kilo_local_path=/lima-kilo`.

Usage
-----
Once the installation is finished, you can run commands as one of the two default users created, tf-test or tf-test2 like this:
```
dcaro@vulcanus$ sudo -i -u toolsbeta.tf-test
toolsbeta.tf-test@vulcanus:~$ pwd
/home/dcaro/.toolforge-lima-kilo/chroot/data/project/tf-test
```

You would be already at the home of the user, and ready to run any toolforge commands.

Extra tools
-----------
Some extra tools are also installed:
* k9s to explore/manage kubernetes
* kubectl
* helm
* helmfile
* docker-compose to manage harbor
* toolforge_download_package.py to download cli packages from gitlab MRs
* helper script harbor-compose, to manage harbor (wrapper around docker-compose)

Debugging tips
--------------
If you want to access directly the api-gateway, you can do so by pointing to `https://127.0.0.1:30003/`, note that you will need the user certs to authenticate:
```
toolsbeta.tf-test@vulcanus:~$ curl --insecure --cert ~/.toolskube/client.crt --key ~/.toolskube/client.key https://127.0.0.1:30003/
This is the Toolforge API gateway!
```

License
-------
[GPL-3.0](//www.gnu.org/copyleft/gpl.html "GPL-3.0")
