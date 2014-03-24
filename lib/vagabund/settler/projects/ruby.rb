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
          machine.ui.detail "Bundling ruby project #{name}..."
          machine.communicate.execute "cd #{config.project_path}; bundle install"
          exec_after :bundle, machine
        end

      end
    end
  end
end
