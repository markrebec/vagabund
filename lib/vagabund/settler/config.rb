require_relative 'packages/config'

module Vagabund
  module Settler
    class Config < Vagrant.plugin(2, :config)
      def packages(*args, &block)
        @packages ||= Packages::Config.new(self, *args)
        @packages.instance_eval &block if block_given?
        @packages
      end

      def packages=(pkgs)
        raise Vagrant::Errors::VagrantError, :invalid_packages_config unless pkgs.is_a?(Array)
        @packages = Packages::Config.new(self, pkgs)
      end

      def add_package(*args, &block)
        packages.add_package *args, &block
      end
      alias_method :package, :add_package
      alias_method :package=, :add_package
      
      def projects
        @projects ||= []
      end

      def projects=(prjs)
        raise Vagrant::Errors::VagrantError, :invalid_projects_config unless prjs.is_a?(Array)
        @projects = prjs
      end

      def project=(prj)
        projects << prj
      end

      def initialize
        super
        Dir['packages/**/*.rb'].each { |package| eval(IO.read(package)) }
      end

    end
  end
end
