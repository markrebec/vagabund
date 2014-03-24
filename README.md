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

To build and install a software package on the guest OS you add them to your provisioner config:

```ruby
config.vm.provision :settle do |settler|
  settler.packages do |packages|
    # Download, extract and build the package using the built-in procs
    package 'epubcheck', '3.0.1', url: 'https://github.com/IDPF/epubcheck/releases/download/v3.0.1/epubcheck-3.0.1.zip'
  
    # Upload the local package, extract and build it using the built-in procs
    package 'my_dependency', '0.3.0', local: '/local/path/to/mydependency-0.3.0.tar.gz'
  end
  
  # You can also add a package outside a packages config block
  settler.package 'my_dependency', '0.3.0', local: '/local/path/to/mydependency-0.3.0.tar.gz'
end
```

The supported sources for pulling the package are: `git: GIT_URL`, `local: LOCAL_PATH`, `url: URL`.

You can override the paths where the work is done with a few configuration options, and you can use a block for an advanced configuration DSL:

```ruby
config.vm.provision :settle do |settler|
  settler.packages do |packages|
    package 'my_dependency', '0.3.0', local: '/local/path/to/mydependency-0.3.0.tar.gz' do |package|
      package.build_root = '/some/local/path'               # the path to which the source package will be pulled (default /tmp)
      package.build_path = '/another/local/path/my_package' # the path where the package will be built (default build_root/name-version)
      package.local_package = '/some/local/package.tar.gz'  # the path to the local package file (default based on source filename)
    end
  end
end
```

There is a built-in extractor that will work for most common file types and a builder and installer that perform simple `./configure && make` and `make install` commands, but you can override these as well as some other key hooks and actions with your own blocks/procs.

```ruby
config.vm.provision :settle do |settler|
  settler.packages do |package|
    package 'mydependency', '0.3.0', local: '/local/path/to/mydependency-0.3.0.tar.gz' do |pkg|
      # Perform a custom action before provisioning the package
      before do
        installed = true # Maybe check something like `which some_binary`
        
        # Allows skipping this package if it's already installed
        skip true if installed
      end
      
      # Custom extractor to extract the pulled package into the build_path
      extractor do |package, machine, channel|
        execute "tar xzf #{local_package} /mydependency/src -C #{build_path}"
      end

      # Perform a custom build and install for the package
      pkg.builder = proc do |package, machine, channel|
        execute "cd #{build_path}; make"
      end

      install_proc = Proc.new do |package, machine, channel|
        sudo "cp #{build_path}/my_custom_binary /usr/bin"
      end
      installer install_proc

      # Or for simple commands, you can pass the command as a string (they will automatically be executed within the build_path)
      builder "make"
      installer "cp my_custom_binary /usr/bin", sudo: true
    end
  end
end
```
There are a number of DSL methods that allow you to pass additional blocks/procs as package actions or before and after hooks, which will be executed within the context of the package instance:

* `before` - Executed before provisioning the package. Also aliased to `before_package`.
* `before_pull` - Executed before pulling the package from it's source.
* `puller` - Override the default behavior for pulling the remote source.
* `after_pull` - Executed after pulling the package.
* `before_extract` - Executed before extracting the package.
* `extractor` - Override the default extractor with your own.
* `after_extract` - Executed after extracting the package.
* `before_build` - Executed before building the package.
* `builder` - Override the default builder with your own.
* `after_build` - Executed after building the package.
* `before_install` - Executed before installing the package.
* `installer` - Override the default installer with your own.
* `after_install` - Executed after installing the package.
* `before_clean` - Executed before cleaning up.
* `cleaner` - Override the default cleaner with your own.
* `after_clean` - Executed after cleaning up.
* `after` - Executed after provisioning the package. Also aliased to `after_package`.

These each provide three arguments to the block, which are the package itself, the machine, and the channel (which is a shortcut for `machine.communicate`). However there are additionally a few helper methods available within these blocks to facilitate communication with the machine and input/output:

* Package: `build_root`, `build_path`, `local_package`
* Communication: `execute`, `sudo`, `test`
* I/O: `ask`, `detail`, `error`, `info`, `output`, `warn`

#### Projects

To automatically check out and prepare (i.e. run bundler for ruby projects) a project you can add a it to your provisioner config:

```ruby
config.vm.provision :settle do |settler|
  settler.projects do |projects|
    # A simple project, it will only be cloned into a local path
    project 'my_project', git: 'git@github.com:example/example.git'

    # A ruby or rails project will be bundled after it is cloned
    project :ruby, 'ruby_project', git: 'git@github.com:example/example.git'
    project :rails, 'my_app', git: 'git@github.com:example/example.git'
  end
  
  # You can also add a project outside a projects config block
  settler.project 'my_project', git: 'git@github.com:example/example.git'
end
```

For ruby/rails projects your gem dependencies will be automatically installed for you with `bundle install`.

You can configure project paths for all or individual projects.

```ruby
config.vm.provision :settle do |settler|
  settler.projects do |projects|
    # All projects that do not override the path will be cloned into /some/local/path/PROJECT_NAME
    projects.path = '/some/local/path'

    # Project ends up in /some/local/path/my_project
    project 'my_project', git: 'git@github.com:example/example.git'

    # Project ends up in /another/path/other_project
    project 'other_project', git: 'git@github.com:example/example.git', path: '/another/path/other_project'

    # Project ends up in /another/path/third_project
    project 'third_project', git: 'git@github.com:example/example.git', projects_path: '/another/path'
  end
end
```

All config options (and some additional features) can also be called through the config DSL when passing a block.

```ruby
config.vm.provision :settle do |settler|
  settler.projects do |projects|
    
    project :ruby, 'my_project', git: 'git@github.com:example/example.git' do |project_config|
      # Project configuration DSL is available within an optional block

      project_config.path = '/path/to/my_project'
      
      # Do something before provisioning the project
      before do |project, machine, channel|
        info "Executing some command on the server..."
        execute "cd #{path}; execute some command on the server"
      end

      # Do something before pulling the project
      before_pull(Proc.new { sudo "execute something as root" })

      # Do something after bundling the project
      after_bundle "execute inline server command"
    end
  
  end
end
```

There are a number of DSL methods that allow you to pass additional blocks/procs as before and after hooks, which will be executed within the context of the project instance:

* `before` - Executed before provisioning the project. Also aliased to `before_project`.
* `before_pull` - Executed before pulling the project from it's source.
* `after_pull` - Executed after pulling the project.
* `before_bundle` - Executed before running bundler (ruby/rails projects only).
* `after_bundle` - Executed after running bundler (ruby/rails projects only).
* `after` - Executed after provisioning the project. Also aliased to `after_project`.

*Unlike packages, projects do not allow you to provide custom blocks/procs for the actual actions, only the before/after hooks.*

These each provide three arguments to the block, which are the project itself, the machine, and the channel (which is a shortcut for `machine.communicate`). However there are additionally a few helper methods available within these blocks to facilitate communication with the machine and input/output:

* Project: `path`
* Communication: `execute`, `sudo`, `test`
* I/O: `ask`, `detail`, `error`, `info`, `output`, `warn`

## Development

Make sure you read the documentation at [http://docs.vagrantup.com/v2/plugins/index.html](http://docs.vagrantup.com/v2/plugins/index.html) to familiarize yourself with basic usage and development practices for vagrant plugins.

**Note:** If you `bundle install` without specifying a `--path` the rubygems version of the `vagrant` binary might override your installed version, even outside of this project's directory.  It is suggested you `bundle install --path ./.bundle` so you can use `bundle exec vagrant` while working on this plugin, but it won't interfere with your installed vagrant.

### Test Box

The default `Vagrantfile` points to a box called `vagabund-test-box` and uses the VirtualBox provider. You will need to add the box manually with `vagrant box add` or edit the `Vagrantfile` to point to an available base box (**but do not commit your changes**). You can use any base box you'd like to test, but it is recommended you use the latest `forthrail/precise64` box available.

If you want to use the `forthrail/precise64` base box, normally you would login to VagrantCloud with `vagrant login`. However, `bundle exec vagrant login` is not available when working with a bundled version of vagrant, which is why we need to install the box manually. The easiest way to do this is to use the URL of the latest `.box` file on S3 directly. Example (replace the URL with the latest version of the base box):

    $ bundle exec vagrant box add vagabund-test-box https://s3.amazonaws.com/forth-rail-devops/vagrant/boxes/forthrail-precise64-0.1.0-virtualbox.box

From here you can use `bundle exec vagrant` as you normally would, which will use the bundled version of vagrant (instead of the system vagrant) and include this plugin automatically.
