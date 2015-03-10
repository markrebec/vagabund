# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'dotenv'
Dotenv.load

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # Example config for Squatter provisioner
  config.vm.provision :squat do |squatter|
    squatter.files = []
  end

  # Example config for Settler provisioner
  config.vm.provision :settle do |settler|
    settler.packages do
    end
    settler.projects do
    end
  end

  config.ssh.forward_agent = true

  config.vm.define "vagabund-testing", primary: true do |machine|
    machine.vm.provider "virtualbox" do |vb, override|
      override.vm.box = "hashicorp/precise64"

      vb.name = "vagabund-testing"
      vb.memory = 2048
      vb.cpus = 2
    end

    #machine.vm.provider :aws do |aws, override|
    #  override.vm.box = "aws/precise64"
    #  override.ssh.username = "ubuntu"
    #  override.ssh.private_key_path = "~/.ssh/id_rsa"
    #  override.vm.synced_folder "./", "/vagrant", disabled: true

    #  aws.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    #  aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    #  aws.keypair_name = "MarkRebecMacbookAir"

    #  aws.instance_type = "m1.large"
    #  aws.tags = {'Name' => 'vagabund-testing'}
    #end
  end
end
