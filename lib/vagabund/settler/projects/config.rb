module Vagabund
  module Settler
    module Projects
      class Config

        def projects_path
          @projects_path ||= '/vagrant'
        end
        alias_method :path, :projects_path

        def projects_path=(path)
          @projects_path = path
        end
        alias_method :path=, :projects_path=

        def projects
          @projects ||= []
        end

        def add_project(*args, &block)
          if args.first.is_a?(Projects::Base)
            prj = args.shift
            prj.config.projects_path ||= projects_path
            prj.configure &block if block_given?
            projects << prj
          else
            args.push({projects_path: projects_path}.merge(args.extract_options!))
            add_project Project.new(*args, &block)
          end
        end
        alias_method :project, :add_project
        alias_method :project=, :add_project

        def method_missing(meth, *args, &block)
          projects.send meth, *args, &block
        end
        
        def respond_to_missing?(meth, include_private=false)
          projects.respond_to? meth, include_private
        end

        protected

        def initialize(*args)
          @settler_config = args.shift if args.first.is_a?(Settler::Config)
          @projects = args.shift if args.first.is_a?(Array)
        end
      end
    end
  end
end
