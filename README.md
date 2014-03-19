Vagabund
========

Vagrant plugin for Forth Rail environments. Provides automatic config management, git operations and the ability to checkout Forth Rail projects and manage services.

# Development

Make sure you read the documentation at [http://docs.vagrantup.com/v2/plugins/index.html](http://docs.vagrantup.com/v2/plugins/index.html) to familiarize yourself with basic usage and development practices for vagrant plugins.

## Test Box

The default `Vagrantfile` points to a box called `vagabund-test-box` and uses the VirtualBox provider. You will need to add the box manually with `vagrant box add` or edit the `Vagrantfile` to point to an available base box (**but do not commit your changes**). You can use any base box you'd like to test, but it is recommended you use the latest `forthrail/precise64` box available.

If you want to use the `forthrail/precise64` base box, normally you would login to VagrantCloud with `vagrant login`. However, `bundle exec vagrant login` is not available when working with a bundled version of vagrant, which is why we need to install the box manually. The easiest way to do this is to use the URL of the latest `.box` file on S3 directly. Example (replace the URL with the latest version of the base box):

    $ bundle exec vagrant box add vagabund-test-box https://s3.amazonaws.com/forth-rail-devops/vagrant/boxes/forthrail-precise64-0.1.0-virtualbox.box


