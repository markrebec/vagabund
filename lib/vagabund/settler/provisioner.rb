require_relative 'packages'
require_relative 'projects'
require_relative 'sources'

module Vagabund
  module Settler
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def provision
        config.packages.each do |package|
          begin
            machine.ui.info "Provisioning package #{package.name}-#{package.version}..."
            package.provision @machine
          rescue Vagrant::Errors::VagrantError => e
            machine.ui.error "Failed to provision package #{package.name}-#{package.version}!"
            machine.ui.detail e.message(false)
            machine.ui.detail "#{e.message} in #{e.backtrace[0]}"
          end
        end
        
        config.projects.each do |project|
          begin
            machine.ui.info "Provisioning project #{project.target_path}"
            project.prepare @machine
          rescue Vagrant::Errors::VagrantError => e
            machine.ui.error "Failed to provision project #{project.target_path}!"
            machine.ui.detail "#{e.message} in #{e.backtrace[0]}"
          end
        end
      end

    end
  end
end
