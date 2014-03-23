require_relative 'package_config'

module Vagabund
  module Settler
    module Packages
      class Base
        attr_reader :config

        def provision(machine)
          exec_before :package, machine

          if skip?
            machine.ui.warn "Skipping package #{name}-#{version} because skip flag was set."
            return
          end

          pull machine
          extract machine
          build machine
          install machine
          clean machine

          exec_after :package, machine
        end

        def build(machine)
          exec_before :build, machine
          machine.ui.detail "Building #{name}-#{version}..."
          action_exec config.builder, machine
          exec_after :build, machine
        rescue StandardError => e
          raise Settler::Errors::PackageBuildError, e
        end

        def clean(machine)
          exec_before :clean, machine
          machine.ui.detail "Cleaning up after #{name}-#{version}..."
          action_exec config.cleaner, machine
          exec_after :clean, machine
        rescue StandardError => e
          raise Settler::Errors::PackageCleanError, e
        end

        def extract(machine)
          exec_before :extract, machine
          machine.ui.detail "Unpacking #{local_file}..."
          action_exec config.extractor, machine
          exec_after :extract, machine
        rescue StandardError => e
          raise Settler::Errors::PackageExtractionError, e
        end

        def install(machine)
          exec_before :install, machine
          machine.ui.detail "Installing #{name}-#{version}..."
          action_exec config.installer, machine
          exec_after :install, machine
        rescue StandardError => e
          raise Settler::Errors::PackageInstallError, e
        end

        def pull(machine)
          exec_before :pull, machine
          machine.ui.detail "Retrieving sources for #{name}-#{version}..."
          action_exec config.puller, machine
          exec_after :pull, machine
        rescue StandardError => e
          raise Settler::Errors::PackagePullError, e
        end

        def exec_before(action, machine)
          hook_exec :before, action, machine
        end

        def exec_after(action, machine)
          hook_exec :after, action, machine
        end

        def hook_exec(hook, action, machine)
          hook_action = "#{hook.to_s}_#{action.to_s.gsub(/[eo]r$/, '')}"
          return if config.send(hook_action).nil? || config.send(hook_action).empty?

          machine.ui.detail "Executing custom :#{hook_action} hooks for package #{name}-#{version}..."
          config.send(hook_action).each do |hact|
            action_exec hact, machine
          end
        rescue StandardError => e
          raise Settler::Errors::PackageError, e
        end

        def action_exec(command, machine)
          self.class.instance_eval do
            [:ask, :detail, :error, :info, :output, :warn].each do |cmd|
              define_method cmd do |*args, &block|
                machine.ui.send cmd, *args, &block
              end
            end
            [:execute, :sudo, :test].each do |cmd|
              define_method cmd do |*args, &block|
                machine.communicate.send cmd, *args, &block
              end
            end
          end

          instance_exec self, machine, machine.communicate, &command if command.is_a?(Proc)

          self.class.instance_eval do
            [:ask, :detail, :error, :info, :output, :warn, :execute, :sudo, :test].each do |cmd|
              undef_method cmd
            end
          end
        end

        def configure(&block)
          config.configure &block
        end

        def local_package
          config.local_package
        end
        alias_method :local_file, :local_package

        def build_path
          config.build_path
        end

        def build_root
          config.build_root
        end

        def name
          config.name
        end

        def version
          config.version
        end

        def source
          config.source
        end

        def skip(s)
          @skip = s unless s.nil?
          @skip
        end
        alias_method :skip=, :skip

        def skip?
          @skip
        end

        protected

        #
        # Base.new 'poppler', '0.24.5', {url: 'http://poppler.freedesktop.org/poppler-0.24.5.tar.xz'}
        #
        # Supported source types:
        #   git: 'git url'
        #   local: '/path/to/local/file'
        #   url: 'http://example.com/path/to/file'
        #   url: 'ftp://user:pass@example.com/path/to/file'
        #   scp: '[user@]example.com:/path/to/file' # this might require ssh forwarding
        def initialize(*args, &block)
          opts = args.extract_options!
          opts = {name: args.shift, version: args.shift}.merge(opts)
          @config = PackageConfig.new(opts, &block)
        end

        def build_path_exists?(machine)
          return machine.communicate.test("[ -d #{build_path} ]") ? true : false
        end

        def package_exists?(machine)
          return machine.communicate.test("[ -f #{existing_package_file(machine)} ]") ? true : false
        end

        def existing_package_file(machine)
          pkg_file = local_file

          while !machine.communicate.test("[ -f #{pkg_file} ]") && !File.extname(pkg_file).empty? do
            pkg_file = File.join(build_root, File.basename(pkg_file, File.extname(pkg_file)))
          end
          pkg_file
        end

      end
    end
  end
end
