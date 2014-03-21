require_relative 'packages'
require_relative 'projects'
require_relative 'sources'

module Vagabund
  module Settler
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def provision
        config.packages.each do |package|
          begin
            package.build @machine
          rescue
            machine.ui.error "Package #{package.name}-#{package.version} failed to build!"
          end
        end
        
        config.projects.each do |project|
          begin
            project.prepare @machine
          rescue
            machine.ui.error "Project #{project.target_path} failed to build!"
          end
        end
      end

    end
  end
end
