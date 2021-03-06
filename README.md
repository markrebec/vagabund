Vagabund
========

Vagrant plugin providing automatic config management, git operations and the ability to checkout projects and manage services. Adds custom provisioners for "squatting" a machine by temporarily copying config files like your vim and git configs and provisioning a user account, and "settling" a machine by easily installing packages of all types and automatically checking out any projects you plan to work on. There is also the "boxer" component, which makes it easier to package and release custom boxes for different providers.

## Usage

### Squatter

Squatter is a provisioner that copies all your personal config files over to the VM automatically to make it feel more like home.

You can configure the host and guest home directories and override or add to the list of config files to be copied. Any relative paths provided will be relative to the home directories, while absolute paths will be preserved.

Really, this can be used to copy any files/directories from the host to the guest, not just "config files". Wildcard operators are not currently supported, but directories will be copied recursively. You can also provide a remote source in the form of a URL or S3 resource (the AWS CLI will be used to copy the file when using S3), or a `proc`.

The default list of config files includes `~/.vimrc`, `~/.viminfo`, `~/.gitconfig` and `~/.ssh/known_hosts`.

```ruby
config.vm.provision :squat do |squatter|
  squatter.host_home = '/Users/markrebec' # the host directory used for relative file paths
  squatter.guest_home = '/home/vagrant'   # the guest directory used for relatvie file paths
  
  squatter.files = ['.vimrc', '.gitconfig', ['file.env', '.env']] # override the default list of files
  squatter.file = '.filename'                                     # home-relative path
  squatter.file = '/path/to/.testfile'                            # absolute path
  squatter.file = ['/host/path/.somefile', '.somefile']           # absolute host path, home-relative guest path
  squatter.file = ['.somefile', '/guest/path/.somefile']          # home-relative host path, absolute guest path
  squatter.file = 'http://example.com/source/file'                # remote source file, home-relative guest path based of remote file basename
  squatter.file = 's3://example-bucket/source/file'               # remote source file, home-relative guest path based of remote file basename
  squatter.file = ['http://example.com/source/file', '.other']    # remote source file, home-relative guest path
  squatter.file = proc { ['.source_file', '.target_file'] }       # must return a string or array, result will be interpreted like the above examples
  squatter.file = [proc { '.source' }, proc { '.target' }]        # must each return a string, results will be interpreted like the above examples
end
```

You can also use squatter to provision a new user account on the guest OS. This is particularly useful if you're creating a custom base box and want a user account other than the default `vagrant` user.

It's important to note that the files copied over by squatter are copied by the **current** user, not the user being created here. You can specify the guest home path to match your new user's home directory, but any files copied will be owned by the **current** ssh user.

```ruby
config.vm.provision :squat do |squatter|
  # Create a user with the given username
  squatter.user.username = 'example'                # required

  # Set the home directory for the user
  squatter.user.home = '/home/example'              # optional
  
  # Set the primary group
  squatter.user.group = 'example'                   # optional

  # Set additional groups
  squatter.user.groups = ['rvm', 'admins']          # optional

  # Set the public key that should be added to .ssh/authorized_keys
  # If not specified, the CURRENT user's authorized_keys file is copied over to the new user
  # Add multiple keys by using an array
  squatter.user.public_key = '/path/to/key.pub'     # optional. a filepath, string or array of filepaths/strings

  # Add an ssh config file for the user
  squatter.user.ssh_config = '/path/to/.ssh/config' # optional. a filepath or string
end
```

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
* `puller` - Override the default puller with your own.
* `after_pull` - Executed after pulling the project.
* `before_bundle` - Executed before running bundler (ruby/rails projects only).
* `bundler` - Override the default bundler with your own (ruby/rails projects only).
* `after_bundle` - Executed after running bundler (ruby/rails projects only).
* `after` - Executed after provisioning the project. Also aliased to `after_project`.

These each provide three arguments to the block, which are the project itself, the machine, and the channel (which is a shortcut for `machine.communicate`). However there are additionally a few helper methods available within these blocks to facilitate communication with the machine and input/output:

* Project: `path`
* Communication: `execute`, `sudo`, `test`
* I/O: `ask`, `detail`, `error`, `info`, `output`, `warn`

### Boxer

#### Requirements

If you plan on using boxer with aws, you'll need the [AWS Command Line Interface](http://aws.amazon.com/cli/) as well as the [vagrant-aws](https://github.com/mitchellh/vagrant-aws) and [vagrant-awsinfo](https://github.com/johntdyer/vagrant-awsinfo) vagrant plugins, which you can install with:

    $ vagrant plugin install vagrant-aws
    $ vagrant plugin install vagrant-awsinfo

#### Usage

Boxer is a new command for vagrant that wraps up the creation of boxes for VirtualBox and AWS. It uses the built in `vagrant package` to package VirtualBox VMs, and packages AWS instances by creating an AMI and a box that points to that AMI.

You can run boxer on a stopped VM with `vagrant boxer machine --name some-box-name`. Passing in a `machine` is optional, and without one all loaded machines will be boxed. The `--name` flag is also optional, and if not passed the name of the current machine (`default` by default) will be used.

**VirtualBox**

    $ vagrant up --provider virtualbox
    $ vagrant halt
    $ vagrant boxer --name mybox-precise64-0.1.0
    $ vagrant destroy -f

This will leave you with a vagrant box file backed by VirtualBox called `mybox-precise64-0.1.0-virtualbox.box` in the current directory.

**AWS**

    $ vagrant up --provider aws
    $ vagrant halt
    $ vagrant boxer --name mybox-precise64-0.1.0
    $ vagrant destroy -f

This will create an EC2 AMI named `mybox-precise64-0.1.0-aws` and leave you with a vagrant box file backed by AWS and pointing to the new AMI called `mybox-precise64-0.1.0-aws.box` in the current directory.

## Development

Make sure you read the documentation at [http://docs.vagrantup.com/v2/plugins/index.html](http://docs.vagrantup.com/v2/plugins/index.html) to familiarize yourself with basic usage and development practices for vagrant plugins.

**Note:** If you `bundle install` without specifying a `--path` the rubygems version of the `vagrant` binary might override your installed version, even outside of this project's directory.  It is suggested you `bundle install --path ./.bundle` so you can use `bundle exec vagrant` while working on this plugin, but it won't interfere with your installed vagrant.

### Test Box

The default `Vagrantfile` points to the default `hashicorp/precise64` box and uses the VirtualBox provider. You can use any base box you'd like for development and testing, just edit the `Vagrantfile` to point to an available base box (**but do not commit your changes**).
