# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "vagabund-test-box"
  
  # Example config for dotfiles provisioner
  config.vm.provision :dotfiles do |dotfiles|
    #dotfiles.host_home = '/Users/markrebec'
    #dotfiles.guest_home = '/home/vagrant'
    
    #dotfiles.files = ['.vimrc', '.gitconfig', ['/host/path/.file', '/guest/path/.file']]
    #dotfiles.file = '.filename'                            # home-relative guest path
    #dotfiles.file = '/path/to/.testfile'                   # absolute path
    #dotfiles.file = ['/host/path/.somefile', '.somefile']  # absolute local path, home-relative guest path
    #dotfiles.file = ['.somefile', '/guest/path/.somefile'] # home-relative local path, absolute guest path
  end

  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "vagabund"
    vb.memory = 2048
    vb.cpus = 2 
  end 
end
