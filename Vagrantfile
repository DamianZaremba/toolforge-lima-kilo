# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Basic VM configuration
  config.vm.box = "debian/bookworm64"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # for harbor
  config.vm.network "forwarded_port", guest: 80, host: 8080
  # for api-gateway
  config.vm.network "forwarded_port", guest: 30003, host: 30003

  # VirtualBox settings
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = ENV['VAGRANT_MEMORY'] || 8192
    vb.cpus = ENV['VAGRANT_CPUS'] || 4
  end
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = ENV['VAGRANT_MEMORY'] || 8192
    libvirt.cpus = ENV['VAGRANT_CPUS'] || 4
  end

  # Provisioners
  config.vm.provision "docker"
  config.vm.provision "docker_compose"

  # skip any non-ansible things (specially .git as it will go really slowly file-by-file)
  ["playbooks", "roles", "ansible.cfg", "hosts.yaml", "requirements.txt", "helpers"].each do |file|
    config.vm.provision "file", source: file, destination: "lima-kilo/"
  end

  # Shell provisioners
  config.vm.provision "install", type: "shell", privileged: false, path: "vagrant/install.sh"
  config.vm.provision "run", type: "shell", privileged: false, path: "vagrant/run_ansible.sh"
end
