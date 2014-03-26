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
          if config.bundler.nil?
            machine.communicate.execute "cd #{config.project_path}; bundle install" do |type,data|
              color = type == :stderr ? :red : :green
              options = {
                color: color,
                new_line: false,
                prefix: false
              }

              machine.ui.detail(data, options)
            end
          else
            action_exec config.bundler, machine
          end
          exec_after :bundle, machine
        rescue StandardError => e
          raise Settler::Errors::ProjectError, e
        end

      end
    end
  end
end
