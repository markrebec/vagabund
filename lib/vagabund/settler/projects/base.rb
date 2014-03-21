module Vagabund
  module Settler
    module Projects
      class Base
        attr_reader :options, :source, :target_path

        def prepare(machine)
          pull machine
        end

        def pull(machine)
          source.pull machine, @target_path
        end

        protected

        #
        # Base.new '/path/to/project', {git: 'git@github.com:/user/repo.git'}
        #
        def initialize(*args, &block)
          @options = OpenStruct.new(args.extract_options!)
          yield @options if block_given?

          raise Vagrant::Errors::VagrantError, :missing_project_path unless args.length > 0
          
          @target_path = args.shift

          if @options.respond_to?(:git) || (@options.respond_to?(:source) && @options.source.to_sym == :git)
            @source = Sources::Git.new(@options.git)
          #elsif @options.respond_to?(:url)
            # http, ftp
          #elsif @options.respond_to?(:scp)
            # scp
          end
        end

      end
    end
  end
end
