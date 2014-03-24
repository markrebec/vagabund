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
            machine.ui.error e.message(false), prefix: false
            machine.ui.detail "#{e.message} in #{[e.backtrace[0..5], '...'].join($/)}", prefix: false
          end
        end
        
        config.projects.each do |project|
          begin
            machine.ui.info "Provisioning project #{project.name}"
            project.provision @machine
          rescue Vagrant::Errors::VagrantError => e
            machine.ui.error "Failed to provision project #{project.name}!"
            machine.ui.error e.message(false), prefix: false
            machine.ui.detail "#{e.message} in #{[e.backtrace[0..5], '...'].join($/)}", prefix: false
          end
        end
      end

    end
  end
end
