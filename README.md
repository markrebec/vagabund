Vagabund
========

Vagrant plugin for Forth Rail environments. Provides automatic config management, git operations and the ability to checkout Forth Rail projects and manage services.

## Usage

### Squatter

Squatter is a provisioner that copies all your personal config files over to the VM automatically to make it feel more like home.

You can configure the host and guest home directories and override or add to the list of config files to be copied. Any relative paths provided will be relative to the home directories, while absolute paths will be preserved.

Really, this can be used to copy any files/directories from the host to the guest, not just "config files". Wildcard operators are not currently supported, but directories will be copied recursively.

The default list of config files includes `~/.vimrc`, `~/.viminfo`, `~/.gitconfig` and `~/.ssh/known_hosts`

See the example block passed to `config.vm.provision :squat` in this project's `Vagrantfile` for usage and configuration options.

### Settler

Settler is a provisioner that allows you to easily install software packages and checkout projects you'll be working on.

You can invoke the provisioner with the following in your `Vagrantfile`:

```ruby
  config.vm.provision :settle do |settler|
    # add software packages with settler.package and projects with settler.project
  end
```

#### Packages

To build and install a software package on the guest OS you add a `Vagabund::Settler::Package` object within your provisioner config:

```ruby
  config.vm.provision :settle do |settler|
    # download, extract and build the package using the built-in builder
    settler.package = Vagabund::Settler::Package('epubcheck', '3.0.1', url: 'https://github.com/IDPF/epubcheck/releases/download/v3.0.1/epubcheck-3.0.1.zip')
    
    # upload the local package, extract and build it using the built-in builder
    settler.package = Vagabund::Settler::Package('mydependency', '0.3.0', local: '/local/path/to/mydependency-0.3.0.tar.gz')
  end
```

There is a built-in extractor that will work for most common file types and a builder that performs a simple `./configure && make && make install`, but you can override both of them with your own blocks.

```ruby
  config.vm.provision :settle do |settler|
    settler.package = Vagabund::Settler::Package('mydependency', '0.3.0', local: '/local/path/to/mydependency-0.3.0.tar.gz') do |pkg|
      # extract a specific path in a gzipped tar file to the pacakge build_path
      pkg.extractor = proc do |package, machine, channel|
        channel.execute "tar xzf #{package.local_file} /mydependency/src -C #{package.build_path}"
      end

      # perform a custom build and install for the package
      pkg.builder = proc do |package, machine, channel|
        channel.execute "cd #{package.build_path}; make"
        channel.sudo    "cp #{package.build_path}/my_custom_binary /usr/bin"
      end
    end
  end
```

#### Projects

To automatically check out and prepare (i.e. run bundler for ruby projects) a project you can add a `Vagabund::Settler::Project` object to your provisioner config:

```ruby
  config.vm.provision :settle do |settler|
    settler.project = Vagabund::Settler::Projects::Base.new("/var/www/example", {git: 'git@github.com:someone/example.git'})
    settler.project = Vagabund::Settler::Projects::Ruby.new("/var/www/mygem", {git: 'git@github.com:someone/mygem.git'})
    settler.project = Vagabund::Settler::Projects::Rails.new("/var/www/myapp", {git: 'git@github.com:someone/myapp.git'})
  end
```

For ruby/rails projects your gem dependencies will be automatically installed for you with `bundle install`.

## Development

Make sure you read the documentation at [http://docs.vagrantup.com/v2/plugins/index.html](http://docs.vagrantup.com/v2/plugins/index.html) to familiarize yourself with basic usage and development practices for vagrant plugins.

### Test Box

The default `Vagrantfile` points to a box called `vagabund-test-box` and uses the VirtualBox provider. You will need to add the box manually with `vagrant box add` or edit the `Vagrantfile` to point to an available base box (**but do not commit your changes**). You can use any base box you'd like to test, but it is recommended you use the latest `forthrail/precise64` box available.

If you want to use the `forthrail/precise64` base box, normally you would login to VagrantCloud with `vagrant login`. However, `bundle exec vagrant login` is not available when working with a bundled version of vagrant, which is why we need to install the box manually. The easiest way to do this is to use the URL of the latest `.box` file on S3 directly. Example (replace the URL with the latest version of the base box):

    $ bundle exec vagrant box add vagabund-test-box https://s3.amazonaws.com/forth-rail-devops/vagrant/boxes/forthrail-precise64-0.1.0-virtualbox.box

From here you can use `bundle exec vagrant` as you normally would, which will use the bundled version of vagrant (instead of the system vagrant) and include this plugin automatically.
