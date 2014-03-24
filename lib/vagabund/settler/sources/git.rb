module Vagabund
  module Settler
    module Sources
      class Git
        attr_reader :origin
        
        def clone(machine, target_path)
          machine.ui.detail "Cloning #{origin} into #{target_path}..."
          machine.communicate.execute "mkdir -p #{File.dirname(target_path)}"
          machine.communicate.execute "git clone #{origin} #{target_path}" do |type,data|
            if [:stderr, :stdout].include?(type)
              color = type == :stdout ? :green : :red
              options = {
                color: color,
                new_line: false,
                prefix: false
              }

              machine.ui.detail(data, options)
            end
          end
          target_path
        end

        def update(machine, target_path)
          machine.ui.detail "Updating #{target_path} from #{origin}..."
          machine.communicate.execute "cd #{target_path}; git pull" do |type,data|
            if [:stderr, :stdout].include?(type)
              color = type == :stdout ? :green : :red
              options = {
                color: color,
                new_line: false,
                prefix: false
              }

              machine.ui.detail(data, options)
            end
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
