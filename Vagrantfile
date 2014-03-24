# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # Example config for Squatter provisioner
  config.vm.provision :squat do |squatter|
  end

  # Example config for Settler provisioner
  config.vm.provision :settle do |settler|
    settler.packages do
    end
    settler.projects do
    end
  end

  # Defaults for test box
  config.vm.box = "vagabund-test-box"
  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "vagabund"
    vb.memory = 2048
    vb.cpus = 2 
  end 
end
