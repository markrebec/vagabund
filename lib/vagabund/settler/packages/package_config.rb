module Vagabund
  module Settler
    module Packages
      class PackageConfig
        attr_reader :config, :source
        
        # Bit of metaprogramming to define methods like builder, installer,
        # before_build, after_install, etc.
        %w(package builder cleaner extractor installer puller).each do |action|
          %w(before after).each do |hook|
            hook_action = "#{hook}_#{action.gsub(/[eo]r$/, '')}"

            # Defines before/after 'hook' methods for each action: before_build,
            # before_pull, after_install, etc.
            define_method hook_action.to_sym do |*args, &block|
              if args.first.is_a?(String)
                command = args.shift
                opts = args.extract_options!

                cmd_proc = Proc.new do |package, machine, channel|
                  cmd = "cd #{package.build_path}; #{command}"
                  execute cmd, {verbose: true}.merge(opts)
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

          if action == 'package'
            alias_method :before, :before_package
            alias_method :after, :after_package
            next
          end

          # Defines custom action methods to override the built-in puller,
          # extractor, builder, installer and cleaner.
          define_method action.to_sym do |*args, &block|
            if args.first.is_a?(String)
              command = args.shift
              opts = args.extract_options!

              cmd_proc = Proc.new do |package, machine, channel|
                cmd = "cd #{package.build_path}; #{command}"
                execute cmd, {verbose: true}.merge(opts)
              end

              config.send "#{action}=".to_sym, cmd_proc
            end

            config.send "#{action}=".to_sym, args.shift if !args.empty? && (args.first.nil? || args.first.is_a?(Proc))
            config.send "#{action}=".to_sym, block if !block.nil? # block_given? doesn't work here

            config.send action.to_sym
          end
          alias_method "#{action}=".to_sym, action.to_sym
          alias_method "#{action.gsub(/[eo]r$/, '')}_with".to_sym, action.to_sym
        end

        def build_root
          config.build_root ||= "/tmp/#{name}-#{version}"
        end

        def build_path
          config.build_path ||= File.join(build_root, "#{name}-#{version}")
        end

        def local_package
          config.local_package ||= File.join(build_root, (File.basename(source.origin) rescue "#{name}-#{version}"))
        end
        alias_method :local_file, :local_package

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
          @config = OpenStruct.new({builder: Package::BUILDER, cleaner: Package::CLEANER, extractor: Package::EXTRACTOR, installer: Package::INSTALLER, puller: Package::PULLER}.merge(args.extract_options!))

          if config.respond_to?(:git)
            @source = Sources::Git.new(config.git)
          elsif config.respond_to?(:url)
            @source = Sources::Url.new(config.url)
          elsif config.respond_to?(:local)
            @source = Sources::Local.new(config.local)
          #elsif config.respond_to?(:scp)
            # remote scp
          end

          configure &block if block_given?
        end
      end
    end
  end
end
