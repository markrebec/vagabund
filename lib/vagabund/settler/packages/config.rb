module Vagabund
  module Settler
    module Packages
      class Config

        def packages
          @packages ||= []
        end

        def add_package(*args, &block)
          if args.first.is_a?(Packages::Base)
            pkg = args.shift
            pkg.apply_block &block if block_given?
            packages << pkg
          else
            add_package Package.new(*args, &block)
          end
        end
        alias_method :package, :add_package
        alias_method :package=, :add_package

        def method_missing(meth, *args, &block)
          packages.send(meth, *args, &block)
        end

        protected

        def initialize(*args)
          @settler_config = args.shift if args.first.is_a?(Settler::Config)
          @packages = args.shift if args.first.is_a?(Array)
        end
      end
    end
  end
end
