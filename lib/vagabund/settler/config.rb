module Vagabund
  module Settler
    class Config < Vagrant.plugin(2, :config)
      def packages
        @packages ||= []
      end

      def packages=(pkgs)
        raise Vagrant::Errors::VagrantError, :invalid_packages_config unless pkgs.is_a?(Array)
        @packages = pkgs
      end

      def package=(pkg)
        packages << pkg
      end
      
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

    end
  end
end
