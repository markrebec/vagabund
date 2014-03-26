module Vagabund
  module Settler
    module Sources
      class Local
        attr_reader :origin
        
        def upload(machine, target_path)
          machine.ui.detail "Uploading #{origin} to #{target_path}..."
          unless machine.communicate.test "[ -d #{File.dirname(target_path)} ]"
            machine.communicate.sudo "mkdir -p #{File.dirname(target_path)}"
            machine.communicate.sudo "chown -R #{machine.ssh_info[:username]} #{File.dirname(target_path)}"
            machine.communicate.sudo "chgrp -R #{machine.ssh_info[:username]} #{File.dirname(target_path)}"
          end
          machine.communicate.upload origin, target_path
          target_path
        end
        alias_method :pull, :upload

        protected

        def initialize(origin)
          @origin = File.expand_path(origin)
        end
      
      end
    end
  end
end
