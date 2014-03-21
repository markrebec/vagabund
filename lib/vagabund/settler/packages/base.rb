module Vagabund
  module Settler
    module Packages
      class Base
        attr_reader :name, :version, :options, :source

        def build(machine)
          pull machine
          extract machine

          if @options.respond_to? :builder
            machine.ui.info "Building package #{name}-#{version} with custom builder..."
            @options.builder.call(self, machine, machine.communicate)
          else
            machine.ui.info "Building package #{name}-#{version} in #{build_path}..."
            build_package machine
          end

          clean machine
        end

        def clean(machine)
          if @options.respond_to? :cleaner
            machine.ui.info "Cleaning up after #{name}-#{version} with custom cleaner..."
            @options.cleaner.call(self, machine, machine.communicate)
          else
            machine.ui.info "Cleaning up after #{name}-#{version}..."
            clean_package machine
          end
        end

        def extract(machine)
          if @options.respond_to? :extractor
            machine.ui.info "Unpacking #{local_file} with custom extractor..."
            @options.extractor.call(self, machine, machine.communicate)
          else
            machine.ui.info "Unpacking #{local_file}..."
            extract_package machine
          end
        end

        def pull(machine)
          if @options.respond_to? :puller
            @options.puller.call(self, machine, machine.communicate)
          else
            pull_package machine
          end
        end

        def local_file
          @local_file ||= "/tmp/#{File.basename(source.origin)}"
        end

        def build_path
          @build_path ||= "/tmp/#{name}-#{version}"
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
          @options = OpenStruct.new(args.extract_options!)
          yield @options if block_given?

          @name = args.shift
          @version = args.shift

          if @options.respond_to?(:git)
            @source = Sources::Git.new(@options.git)
          elsif @options.respond_to?(:url)
            @source = Sources::Url.new(@options.url)
          elsif @options.respond_to?(:local)
            @source = Sources::Local.new(@options.local)
          #elsif @options.respond_to?(:scp)
            # remote scp
          end
        end

        def build_package(machine)
          begin
            machine.communicate.execute "cd #{build_path}; ./configure && make"
            machine.communicate.sudo "cd #{build_path}; make install"
          rescue
            raise Vagrant::Errors::VagrantError, :package_build_error
          end
        end

        def clean_package(machine)
          machine.communicate.sudo "rm -rf #{local_file} #{build_path}"
        end

        def extract_package(machine)
          if File.directory?(local_file)
            machine.communicate.execute "cp -r #{local_file} #{build_path}" if local_file != build_path
          else
            local_ext = File.extname(local_file)

            # TODO this should better handle different combinations. For example right now a .tar.zip wouldn't work, a .gz wouldn't work, but a .zip or a .tar.gz DOES work
            case local_ext
            when '.gz', '.bz', '.bz2', '.xz'
              machine.communicate.sudo "rm -rf #{File.join(File.dirname(local_file), File.basename(local_file, local_ext))}"
              
              case local_ext
              when '.gz'
                machine.communicate.execute "cd #{File.dirname(local_file)}; gunzip #{local_file}"
              when '.bz', '.bz2'
                machine.communicate.execute "cd #{File.dirname(local_file)}; bunzip2 #{local_file}"
              when '.xz'
                machine.communicate.execute "cd #{File.dirname(local_file)}; xz -d #{local_file}"
              end
              
              @local_file = File.join(File.dirname(local_file), File.basename(local_file, local_ext))
              extract_package(machine) if ['.gz', '.bz', '.bz2', '.xz', '.zip', '.tar'].include?(File.extname(local_file))
            when '.zip'
              machine.communicate.execute "cd #{File.dirname(local_file)}; unzip #{local_file} -d #{build_path}"
              machine.communicate.execute("cd #{build_path}; mv #{File.basename(local_file, local_ext)}/* ./") rescue nil
              machine.communicate.execute("cd #{build_path}; mv #{File.basename(local_file, local_ext)}/.* ./") rescue nil
              machine.communicate.execute("cd #{build_path}; rm -rf #{File.basename(local_file, local_ext)}") rescue nil
            when '.tar'
              machine.communicate.execute "mkdir -p #{build_path}"
              begin
                machine.communicate.execute "cd #{File.dirname(local_file)}; tar xf #{local_file} #{File.basename(local_file, local_ext)} -C #{build_path}"
              rescue
                begin
                  machine.communicate.execute "cd #{File.dirname(local_file)}; tar xf #{local_file} #{name}-#{version} -C #{build_path}"
                rescue
                  machine.communicate.execute "cd #{File.dirname(local_file)}; tar xf #{local_file} -C #{build_path}"
                end
              end
            end
          end
        end

        def pull_package(machine)
          machine.communicate.sudo "rm -rf #{local_file} #{build_path}"
          source.pull machine, local_file
        end

      end
    end
  end
end
