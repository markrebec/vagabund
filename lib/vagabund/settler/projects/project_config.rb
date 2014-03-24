module Vagabund
  module Settler
    module Projects
      class ProjectConfig
        attr_reader :config, :source
        
        # Bit of metaprogramming to define methods like builder, installer,
        # before_build, after_install, etc.
        %w(project bundler puller).each do |action|
          %w(before after).each do |hook|
            hook_action = (action == 'bundler') ? "#{hook}_bundle" : "#{hook}_#{action.gsub(/[eo]r$/, '')}"

            # Defines before/after 'hook' methods for each action: before_build,
            # before_pull, after_install, etc.
            define_method hook_action.to_sym do |*args, &block|
              if args.first.is_a?(String)
                command = args.shift
                opts = args.extract_options!

                cmd_proc = Proc.new do |project, machine, channel|
                  cmd = "cd #{project.build_path}; #{command}"
                  opts[:sudo] ? channel.sudo(cmd) : channel.execute(cmd)
                end

                config.send "#{hook_action}=".to_sym, [] if config.send(hook_action.to_sym).nil?
                config.send(hook_action.to_sym) << cmd_proc
              end

              if !args.empty? && (args.first.nil? || args.first.is_a?(Proc))
                config.send "#{hook_action}=".to_sym, [] if config.send(hook_action.to_sym).nil?
                config.send(hook_action.to_sym) << args.shift
              end

              if !block.nil? # block_given? doesn't work here
                config.send "#{hook_action}=".to_sym, [] if config.send(hook_action.to_sym).nil?
                config.send(hook_action.to_sym) << block
              end

              config.send "#{hook_action}".to_sym
            end
          end

          if action == 'project'
            alias_method :before, :before_project
            alias_method :after, :after_project
            next
          end

          # Defines custom action methods to override the built-in puller,
          # extractor, builder, installer and cleaner.
          define_method action.to_sym do |*args, &block|
            if args.first.is_a?(String)
              command = args.shift
              opts = args.extract_options!

              cmd_proc = Proc.new do |project, machine, channel|
                cmd = "cd #{project.build_path}; #{command}"
                opts[:sudo] ? channel.sudo(cmd) : channel.execute(cmd)
              end

              config.send "#{action}=".to_sym, cmd_proc
            end

            config.send "#{action}=".to_sym, args.shift if !args.empty? && (args.first.nil? || args.first.is_a?(Proc))
            config.send "#{action}=".to_sym, block if !block.nil? # block_given? doesn't work here

            config.send action.to_sym
          end
          alias_method "#{action}=".to_sym, action.to_sym
          alias_method "#{(action == 'bundle') ? 'bundle' : action.gsub(/[eo]r$/, '')}_with".to_sym, action.to_sym
        end
        
        def projects_path
          config.projects_path ||= '/vagrant'
        end

        def projects_path=(path)
          config.projects_path = path
        end
        
        def project_path
          config.project_path ||= File.join(config.projects_path, name)
        end

        def project_path=(path)
          config.project_path = path
        end

        def configure(&block)
          instance_eval &block if block_given?
        end

        def method_missing(meth, *args, &block)
          config.send meth, *args, &block
        end

        def respond_to_missing?(meth, include_private=false)
          config.respond_to? meth, include_private
        end

        protected

        def initialize(*args, &block)
          @config = OpenStruct.new(args.extract_options!)

          configure &block if block_given?

          if config.respond_to?(:git)
            @source = Sources::Git.new(config.git)
          elsif config.respond_to?(:url)
            @source = Sources::Url.new(config.url)
          elsif config.respond_to?(:local)
            @source = Sources::Local.new(config.local)
          #elsif config.respond_to?(:scp)
            # remote scp
          end
        end
      end
    end
  end
end
