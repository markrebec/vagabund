# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # Example config for Squatter provisioner
  
  config.vm.provision :squat do |squatter|
    #squatter.host_home = '/Users/markrebec'
    #squatter.guest_home = '/home/vagrant'
    
    #squatter.files = ['.vimrc', '.gitconfig', ['/host/path/.file', '/guest/path/.file']]
    #squatter.file = '.filename'                            # home-relative guest path
    #squatter.file = '/path/to/.testfile'                   # absolute path
    #squatter.file = ['/host/path/.somefile', '.somefile']  # absolute local path, home-relative guest path
    #squatter.file = ['.somefile', '/guest/path/.somefile'] # home-relative local path, absolute guest path
  end

  # Example config for Settler provisioner

  config.vm.provision :settle do |settler|

    settler.packages do
      #add_package Vagabund::Settler::Package.new('ttf2eot', '0.0.2-2', {local: '~/Sites/shelter/base/src/ttf2eot-0.0.2-2.tar'}) do |pkg|
      #  pkg.builder = proc do |package, machine, channel|
      #    machine.ui.warn "HIIIIII"
      #  end
      #end
      
      #package 'ttf2eot', '0.0.2-2', {local: '~/Sites/shelter/base/src/ttf2eot-0.0.2-2.tar'} do |pkg|
      #  builder do |package, machine, channel|
      #    machine.ui.warn "HIIIIII"
      #  end
      #end
    end

    #settler.package = Vagabund::Settler::Package.new('poppler', '0.24.5', {url: 'http://poppler.freedesktop.org/poppler-0.24.5.tar.xz'}) do |pkg|
    settler.package = Vagabund::Settler::Package.new('poopler', '69') do |pkg|
      puller do |package, machine, channel|
        @local_file = "/tmp/#{name}-#{version}.tar.xz"
        channel.execute "curl -L -o #{local_file} http://poppler.freedesktop.org/poppler-0.24.5.tar.xz"
      end

      builder do |package, machine, channel|
        #channel.execute "cd #{package.build_path}; ./configure --prefix=/usr --sysconfdir=/etc --enable-xpdf-headers && make"
      end
      installer do |package, machine, channel|
        #channel.sudo "cd #{package.build_path}; make install"
      end
      cleaner 'rm -rf /tmp/poppler-0.24.5', sudo: true
    end
    
    #settler.package = Vagabund::Settler::Package.new('poppler-data', '0.4.6', {url: 'http://poppler.freedesktop.org/poppler-data-0.4.6.tar.gz'}) do |pkg|
    #  pkg.builder = proc do |package, machine, channel|
    #    channel.sudo    "cd #{package.build_path}; make prefix=/usr install"
    #  end
    #end
    
    #settler.package = Vagabund::Settler::Package.new('fontforge', '20120731-b', {local: '~/Sites/shelter/base/src/fontforge-20120731-b.tar'}) do |pkg|
    #  pkg.builder = proc do |package, machine, channel|
    #    channel.execute "cd #{package.build_path}; ./configure --prefix=/usr && make"
    #    channel.sudo    "cd #{package.build_path}; make install && make install_libs"
    #  end
    #end
    
    #settler.package = Vagabund::Settler::Package.new('pdf2htmlEX', '0.9', {url: 'https://github.com/coolwanglu/pdf2htmlEX/archive/v0.9.tar.gz'}) do |pkg|
    #  pkg.builder = proc do |package, machine, channel|
    #    channel.execute "cd #{package.build_path}; cmake . && make"
    #    channel.sudo    "cd #{package.build_path}; make install"
    #  end
    #end
    
    #settler.package = Vagabund::Settler::Package.new('ttf2eot', '0.0.2-2', {local: '~/Sites/shelter/base/src/ttf2eot-0.0.2-2.tar'}) do |pkg|
    #  pkg.builder = proc do |package, machine, channel|
    #    channel.execute "cd #{package.build_path}; make"
    #    channel.sudo    "cp #{package.build_path}/ttf2eot /usr/bin"
    #  end
    #end
    
    #settler.packages do
    #  package Vagabund::Settler::Package.new('epubcheck', '3.0.1', {url: 'https://github.com/IDPF/epubcheck/releases/download/v3.0.1/epubcheck-3.0.1.zip'}) do |pkg|
    #    pkg.builder = proc do |package, machine, channel|
    #      channel.sudo "cp -r #{package.build_path} /usr/share/"
    #      channel.sudo 'echo "#!/usr/bin/env bash" > /usr/bin/epubcheck'
    #      channel.sudo 'echo "" >> /usr/bin/epubcheck'
    #      channel.sudo "echo \"/usr/bin/env java -jar /usr/share/#{File.basename(package.build_path)}/#{File.basename(package.build_path)}.jar $1\" >> /usr/bin/epubcheck"
    #      channel.sudo 'chmod +x /usr/bin/epubcheck'
    #    end
    #  end
    #end
    
    #settler.package = Vagabund::Settler::Package.new('kindlegen', '2.9', {url: 'http://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz'}) do |pkg|
    #  pkg.builder = proc do |package, machine, channel|
    #    channel.sudo    "cp #{package.build_path}/kindlegen /usr/bin"
    #  end
    #end
    
    
    #settler.project = Vagabund::Settler::Projects::Ruby.new("/tmp/excursion_#{Time.now.to_i}", {git: 'git@github.com:markrebec/excursion.git'})
    #settler.project = Vagabund::Settler::Projects::Rails.new("/tmp/cockpit_#{Time.now.to_i}", {git: 'git@github.com:Graphicly/cockpit.git'})
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
