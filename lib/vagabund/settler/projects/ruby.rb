module Vagabund
  module Settler
    module Projects
      class Ruby < Base
        
        def prepare(machine)
          super
          bundle machine
        end
        
        protected

        def bundle(machine)
          machine.ui.info "Bundling ruby project in #{@target_path}..."
          machine.communicate.execute "cd #{@target_path}; bundle install"
        end

      end
    end
  end
end
