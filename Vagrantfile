# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "vagabund-test-box"
  
  # Example config for squatter provisioner
  config.vm.provision :squat do |squatter|
    #squatter.host_home = '/Users/markrebec'
    #squatter.guest_home = '/home/vagrant'
    
    #squatter.files = ['.vimrc', '.gitconfig', ['/host/path/.file', '/guest/path/.file']]
    #squatter.file = '.filename'                            # home-relative guest path
    #squatter.file = '/path/to/.testfile'                   # absolute path
    #squatter.file = ['/host/path/.somefile', '.somefile']  # absolute local path, home-relative guest path
    #squatter.file = ['.somefile', '/guest/path/.somefile'] # home-relative local path, absolute guest path
  end

  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "vagabund"
    vb.memory = 2048
    vb.cpus = 2 
  end 
end
