module Vagabund
  module Settler
    module Projects
      class Ruby < Base
        
        def provision(machine)
          exec_before :project, machine
          pull machine
          bundle machine
          exec_after :project, machine
        end
        
        def bundle(machine)
          exec_before :bundle, machine
          machine.ui.detail "Bundling #{self.class.name.split('::').last.downcase} project #{name}..."
          machine.communicate.execute "cd #{config.project_path}; bundle install" do |type,data|
            color = type == :stderr ? :red : :green
            options = {
              color: color,
              new_line: false,
              prefix: false
            }

            machine.ui.detail(data, options)
          end
          exec_after :bundle, machine
        end

      end
    end
  end
end
