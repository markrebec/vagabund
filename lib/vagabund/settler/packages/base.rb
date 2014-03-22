require_relative 'package_config'

module Vagabund
  module Settler
    module Packages
      class Base
        attr_reader :name, :version, :config, :source

        def provision(machine)
          pull machine
          extract machine
          build machine
          install machine
          clean machine
        end

        def build(machine)
          machine.ui.detail "Building package #{name}-#{version}..."
          action_exec machine, config.builder
          #instance_exec self, machine, machine.communicate, &config.builder
        rescue StandardError => e
          raise Settler::Errors::PackageBuildError, e
        end

        def clean(machine)
          machine.ui.detail "Cleaning up after #{name}-#{version}..."
          action_exec machine, config.cleaner
          #instance_exec self, machine, machine.communicate, &config.cleaner
        rescue StandardError => e
          raise Settler::Errors::PackageCleanError, e
        end

        def extract(machine)
          machine.ui.detail "Unpacking #{local_file}..."
          action_exec machine, config.extractor
          #instance_exec self, machine, machine.communicate, &config.extractor
        rescue StandardError => e
          raise Settler::Errors::PackageExtractionError, e
        end

        def install(machine)
          machine.ui.detail "Installing #{name}-#{version}..."
          action_exec machine, config.installer
          #instance_exec self, machine, machine.communicate, &config.installer
        rescue StandardError => e
          raise Settler::Errors::PackageInstallError, e
        end

        def pull(machine)
          machine.ui.detail "Retrieving sources for #{name}-#{version}..."
          action_exec machine, config.puller
          #instance_exec self, machine, machine.communicate, &config.puller
        rescue StandardError => e
          raise Settler::Errors::PackagePullError, e
        end

        def action_exec(machine, command)
          instance_exec self, machine, machine.communicate, &command if command.is_a?(Proc)
        end

        def local_file
          @local_file ||= "/tmp/#{File.basename(source.origin)}"
        end

        def build_path
          @build_path ||= "/tmp/#{name}-#{version}"
        end

        def configure(&block)
          config.configure &block
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
          @config = PackageConfig.new(args.extract_options!, &block)

          @name = args.shift
          @version = args.shift

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

        def build_path_exists?(machine)
          return machine.communicate.test("[ -d #{build_path} ]") ? true : false
        end

        def package_exists?(machine)
          return machine.communicate.test("[ -f #{existing_package_file(machine)} ]") ? true : false
        end

        def existing_package_file(machine)
          pkg_file = local_file

          while !machine.communicate.test("[ -f #{pkg_file} ]") && !File.extname(pkg_file).empty? do
            pkg_file = File.join(File.dirname(pkg_file), File.basename(pkg_file, File.extname(pkg_file)))
          end
          pkg_file
        end

      end
    end
  end
end
