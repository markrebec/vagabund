module Vagabund
  module Settler
    module Sources
      class Local
        attr_reader :origin
        
        def upload(machine, target_path)
          machine.ui.info "Uploading #{origin} to #{target_path}..."
          machine.communicate.execute "mkdir -p #{File.dirname(target_path)}"
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
