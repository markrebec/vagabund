module Vagabund
  module Settler
    module Projects
      class Ruby < Base
        
        def provision(machine)
          super
          bundle machine
        end
        
        def bundle(machine)
          machine.ui.detail "Bundling ruby project #{name}..."
          machine.communicate.execute "cd #{config.project_path}; bundle install"
        end

      end
    end
  end
end
