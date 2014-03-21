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
          rescue Vagrant::Errors::VagrantError => e
            machine.ui.error "Failed to provision package #{package.name}-#{package.version}!"
            machine.ui.error "  #{e.message(false)}"
            machine.ui.error "  #{e.message} in #{e.backtrace[0]}"
          end
        end
        
        config.projects.each do |project|
          begin
            project.prepare @machine
          rescue Vagrant::Errors::VagrantError => e
            machine.ui.error "Failed to provision project #{project.target_path}!"
            machine.ui.error "#{e.message} in #{e.backtrace[0]}"
          end
        end
      end

    end
  end
end
