# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "forthrail/precise64"

  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "vagabund"
    vb.memory = 2048
    vb.cpus = 2 
  end 
end
