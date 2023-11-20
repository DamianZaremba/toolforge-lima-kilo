# Vagrant Setup

## Prerequisites

Before you proceed with the Vagrant setup, make sure you have the following prerequisites installed:

1. Vagrant: If you haven't installed Vagrant yet, you can [download it from here](https://www.vagrantup.com/downloads).
2. VirtualBox: Vagrant uses VirtualBox as the default provider.
[Download and install it from here](https://www.virtualbox.org/wiki/Downloads) if you haven't already.
You can also choose another provider; in that case, you need to modify the Vagrantfile.
3. [Vagrant Docker Compose Plugin](https://github.com/leighmcculloch/vagrant-docker-compose):
This project uses Docker Compose through Vagrant. Install the plugin by running the following command:

   ```bash
   vagrant plugin install vagrant-docker-compose
   ```

## Setup Instructions

1. Start Vagrant
Assuming you have already cloned the repository to your local machine, navigate to the project root directory
and start the Vagrant machine:
 
   ```bash
   vagrant up
   ```

   * To run specific provisioning steps, you can use the --provision-with flag.
   For example, to run only `setup` and `install`:

      ```bash
      vagrant up --provision-with setup,install 
      ```

2. SSH into the Vagrant Machine: Once the machine is up, you can SSH into it.

   ```bash
   vagrant ssh 
   ```

3. Stop Vagrant: When you're done, you can either suspend, halt, or destroy the Vagrant machine to free up resources.

   ```bash
   vagrant suspend  # to suspend
   vagrant halt     # to stop
   vagrant destroy  # to remove
   ```

## Ansible Provisioner Issue

Due to a [known issue](https://github.com/hashicorp/vagrant/issues/13234) with Vagrant's Ansible provisioner, Vagrant may incorrectly identify the Ansible version
and fall back to a compatibility mode for Ansible version '1.8', even when a newer version is installed.
This issue is particularly prevalent on various versions of Ubuntu and Debian as the host and guest operating systems.
For this reason, the setup is not currently using the native Ansible provisioner.

## Troubleshooting

### Running out of disk space

If your Vagrantbox runs out of disk space, it's most likely because of Docker images filling it up.
If `docker prune` and other attempts to free enough space is not enough, you might need to resize the disk.
For instance, to allocate 100GB to your Vagrant box, add the following line to the Vagrantfile:

```bash
Vagrant.configure("2") do |config|
  # Other config ...
  config.vm.disk :disk, size: "100GB", primary: true
```

For this to take effect, you will need to do `vagrant halt` followed by `vagrant up`.

This will not automatically resize your filesystem however. You will need to do this manually:

```bash
$ ssh vagrant
vagrant@host:~$ sudo resize2fs /dev/sda1 
```
