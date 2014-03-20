require_relative 'projects'
require_relative 'sources'

module Vagabund
  module Settler
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def provision
        config.projects.each do |project|
          project.prepare @machine
        end
      end

    end
  end
end
