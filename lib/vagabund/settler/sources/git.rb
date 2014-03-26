module Vagabund
  module Settler
    module Sources
      class Git
        attr_reader :origin
        
        def clone(machine, target_path)
          machine.ui.detail "Cloning #{origin} into #{target_path}..."
          unless machine.communicate.test "[ -d #{File.dirname(target_path)} ]"
            machine.communicate.sudo "mkdir -p #{File.dirname(target_path)}"
            machine.communicate.sudo "chown -R #{machine.ssh_info[:username]} #{File.dirname(target_path)}"
            machine.communicate.sudo "chgrp -R #{machine.ssh_info[:username]} #{File.dirname(target_path)}"
          end
          machine.communicate.execute "git clone #{origin} #{target_path}" do |type,data|
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

        def update(machine, target_path)
          machine.ui.detail "Updating #{target_path} from #{origin}..."
          machine.communicate.execute "cd #{target_path}; git pull" do |type,data|
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

        def pull(machine, target_path)
          if machine.communicate.test "[ -d #{target_path} ]"
            update machine, target_path
          else
            clone machine, target_path
          end
        end

        protected

        def initialize(origin)
          @origin = origin
        end
      
      end
    end
  end
end
