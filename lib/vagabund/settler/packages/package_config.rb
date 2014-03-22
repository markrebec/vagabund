module Vagabund
  module Settler
    module Packages
      class PackageConfig
        attr_reader :config
        
        BUILDER = Proc.new do |package, machine, channel|
          channel.execute "cd #{build_path}; ./configure && make"
        end

        CLEANER = Proc.new do |package, machine, channel|
          channel.sudo "rm -rf #{local_file} #{build_path}"
        end

        EXTRACTOR = Proc.new do |package, machine, channel|
          if build_path_exists?(machine)
            machine.ui.warn "Build path #{build_path} already exists, using it for the build. If you would like to use a clean source tree, you should manually remove it and run `vagrant provision` again."
          elsif File.directory?(local_file)
            channel.execute "cp -r #{local_file} #{build_path}" if local_file != build_path
          else
            local_ext = File.extname(local_file)

            # TODO this should better handle different combinations. For example right now a .tar.zip wouldn't work, a .gz wouldn't work, but a .zip or a .tar.gz DOES work
            case local_ext
            when '.gz', '.bz', '.bz2', '.xz'
              channel.sudo "rm -rf #{File.join(File.dirname(local_file), File.basename(local_file, local_ext))}"
              
              case local_ext
              when '.gz'
                channel.execute "cd #{File.dirname(local_file)}; gunzip #{local_file}"
              when '.bz', '.bz2'
                channel.execute "cd #{File.dirname(local_file)}; bunzip2 #{local_file}"
              when '.xz'
                channel.execute "cd #{File.dirname(local_file)}; xz -d #{local_file}"
              end
              
              @local_file = File.join(File.dirname(local_file), File.basename(local_file, local_ext))
              extract(machine) if ['.gz', '.bz', '.bz2', '.xz', '.zip', '.tar'].include?(File.extname(local_file))
            when '.zip'
              channel.execute "cd #{File.dirname(local_file)}; unzip #{local_file} -d #{build_path}"
              channel.execute("cd #{build_path}; mv #{File.basename(local_file, local_ext)}/* ./") rescue nil
              channel.execute("cd #{build_path}; mv #{File.basename(local_file, local_ext)}/.* ./") rescue nil
              channel.execute("cd #{build_path}; rm -rf #{File.basename(local_file, local_ext)}") rescue nil
            when '.tar'
              channel.execute "mkdir -p #{build_path}"
              begin
                channel.execute "cd #{File.dirname(local_file)}; tar xf #{local_file} #{File.basename(local_file, local_ext)} -C #{build_path}"
              rescue
                begin
                  channel.execute "cd #{File.dirname(local_file)}; tar xf #{local_file} #{name}-#{version} -C #{build_path}"
                rescue
                  channel.execute "cd #{File.dirname(local_file)}; tar xf #{local_file} -C #{build_path}"
                end
              end
            end
          end
        end
        
        INSTALLER = Proc.new do |package, machine, channel|
          channel.sudo "cd #{build_path}; make install"
        end

        PULLER = Proc.new do |package, machine, channel|
          if package_exists?(machine)
            @local_file = existing_package_file(machine)
            machine.ui.warn "Package #{local_file} already exists, using it for the build. If you would like to re-download the package, you should manually remove it then run `vagrant provision` again."
          else
            source.pull machine, local_file
          end
        end
        
        %w(builder cleaner extractor installer puller).each do |action|
          define_method action.to_sym do |*args, &block|
            if args.first.is_a?(String)
              command = args.shift
              opts = args.extract_options!

              cmd_proc = Proc.new do |package, machine, channel|
                opts[:sudo] ? channel.sudo(command) : channel.execute(command)
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
          @config = OpenStruct.new({builder: BUILDER, cleaner: CLEANER, extractor: EXTRACTOR, installer: INSTALLER, puller: PULLER}.merge(args.extract_options!))
          configure &block if block_given?
        end
      end
    end
  end
end
