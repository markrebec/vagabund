require_relative 'project_config'

module Vagabund
  module Settler
    module Projects
      class Base
        attr_reader :config

        def name
          config.name
        end

        def project_path
          config.project_path
        end

        def provision(machine)
          pull machine
        end

        def pull(machine)
          config.source.pull machine, project_path
        end

        protected

        #
        # Base.new 'my_project', {git: 'git@github.com:/user/repo.git'}
        #
        def initialize(*args, &block)
          opts = args.extract_options!
          opts = {name: args.shift}.merge(opts)
          @config = ProjectConfig.new(opts, &block)
        end

      end
    end
  end
end
