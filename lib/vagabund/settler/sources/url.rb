module Vagabund
  module Settler
    module Sources
      class Url
        attr_reader :origin
        
        def download(machine, target_path)
          machine.ui.detail "Downloading #{origin} to #{target_path}..."
          unless machine.communicate.test "[ -d #{File.dirname(target_path)} ]"
            machine.communicate.sudo "mkdir -p #{File.dirname(target_path)}"
            machine.communicate.sudo "chown -R #{machine.ssh_info[:username]} #{File.dirname(target_path)}"
            machine.communicate.sudo "chgrp -R #{machine.ssh_info[:username]} #{File.dirname(target_path)}"
          end
          machine.communicate.execute "curl -L -o #{target_path} #{origin}" do |type,data|
            color = type == :stderr ? :red : :green
            options = {
              color: color,
              new_line: false,
              prefix: false
            }

            machine.ui.detail(data, options)
          end
          target_path
        end
        alias_method :pull, :download

        protected

        def initialize(origin)
          @origin = origin
        end
      
      end
    end
  end
end
