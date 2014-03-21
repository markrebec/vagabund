module Vagabund
  module Settler
    module Sources
      class Git
        attr_reader :origin
        
        def clone(machine, target_path)
          machine.ui.detail "Cloning #{origin} into #{target_path}..."
          machine.communicate.execute "mkdir -p #{File.dirname(target_path)}"
          machine.communicate.execute "git clone #{origin} #{target_path}"
          target_path
        end
        alias_method :pull, :clone

        protected

        def initialize(origin)
          @origin = origin
        end
      
      end
    end
  end
end
