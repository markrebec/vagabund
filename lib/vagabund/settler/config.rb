module Vagabund
  module Settler
    class Config < Vagrant.plugin(2, :config)
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
