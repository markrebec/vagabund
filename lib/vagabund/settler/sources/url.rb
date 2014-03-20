module Vagabund
  module Settler
    module Sources
      class Url
        attr_reader :origin
        
        def download(machine, target_path)
          machine.ui.info "Downloading #{origin} to #{target_path}..."
          machine.communicate.execute "mkdir -p #{File.dirname(target_path)}"
          machine.communicate.execute "curl -L -o #{target_path} #{origin}"
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
