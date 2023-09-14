# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  # Basic VM configuration
  config.vm.box = "debian/bullseye64"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # VirtualBox settings
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = ENV['VAGRANT_MEMORY'] || 8192 
    vb.cpus = ENV['VAGRANT_CPUS'] || 4
  end

  # Provisioners
  config.vm.provision "docker"
  config.vm.provision "docker_compose"

#  config.vm.provision "file", source: "./requirements.txt", destination: "/tmp/requirements.txt"
#  config.vm.provision "file", source: "./setup.sh", destination: "setup.sh"

  # Shell provisioners
  config.vm.provision "setup", type: "shell", privileged: false, path: "vagrant/setup.sh"
  config.vm.provision "install", type: "shell", privileged: false, path: "vagrant/install.sh"
  config.vm.provision "run", type: "shell", privileged: false, inline: <<-SHELL
    cd lima-kilo
    ansible-playbook -KD playbooks/kind-install.yaml 
  SHELL

#  https://github.com/hashicorp/vagrant/issues/13234 
#  config.vm.provision "ansible" do |ansible|
#    ansible.playbook = "playbooks/kind-install.yaml"
#    ansible.extra_vars = {
#      ansible_become: true,  # Equivalent to -K option
#      ansible_become_ask_pass: true  # Equivalent to -D option
#    }
#  end
end
