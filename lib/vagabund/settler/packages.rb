require_relative 'errors'
require_relative 'packages/base'

module Vagabund
  module Settler
    module Packages
    end

    class Package < Packages::Base
      EXTENSIONS = ['.gz', '.bz', '.bz2', '.xz', '.zip', '.tar', '.tgz', '.tbz', '.tbz2', '.txz']

      BUILDER = Proc.new do |package, machine, channel|
        execute "cd #{build_path}; ./configure && make", verbose: true
      end

      CLEANER = Proc.new do |package, machine, channel|
        sudo "rm -rf #{build_root}"
      end

      EXTRACTOR = Proc.new do |package, machine, channel|
        if build_path_exists?(machine)
          machine.ui.warn "Build path #{build_path} already exists, using it for the build. If you would like to use a clean source tree, you should manually remove it and run `vagrant provision` again."
        elsif File.directory?(local_package)
          execute "cp -r #{local_package} #{build_path}" if local_package != build_path
        else
          execute "mkdir -p #{build_path}"
          local_ext = File.extname(local_package)

          case local_ext
          when '.gz'
            execute "cd #{build_root}; gzip -dc #{local_package} > #{build_path}/#{File.basename(local_package, local_ext)}"
          when '.tgz'
            execute "cd #{build_root}; gzip -dc #{local_package} > #{build_path}/#{File.basename(local_package, local_ext)}.tar"
          when '.bz', '.bz2'
            execute "cd #{build_root}; bzip2 -dc #{local_package} > #{build_path}/#{File.basename(local_package, local_ext)}"
          when '.tbz', '.tbz2'
            execute "cd #{build_root}; bzip2 -dc #{local_package} > #{build_path}/#{File.basename(local_package, local_ext)}.tar"
          when '.xz'
            execute "cd #{build_root}; xz -dc #{local_package} > #{build_path}/#{File.basename(local_package, local_ext)}"
          when '.txz'
            execute "cd #{build_root}; xz -dc #{local_package} > #{build_path}/#{File.basename(local_package, local_ext)}.tar"
          when '.zip'
            execute "cd #{build_root}; unzip #{local_package} -d #{build_path}"
            execute("cd #{build_path}; mv #{File.basename(local_package, local_ext)}/* ./") rescue nil
            execute("cd #{build_path}; mv #{File.basename(local_package, local_ext)}/.* ./") rescue nil
            execute("cd #{build_path}; mv #{name}-#{version}/* ./") rescue nil
            execute("cd #{build_path}; mv #{name}-#{version}/.* ./") rescue nil
            execute("cd #{build_path}; rm -rf #{File.basename(local_package, local_ext)}") rescue nil
          when '.tar'
            begin
              execute "cd #{build_root}; tar xf #{local_package} #{File.basename(local_package, local_ext)} -C #{build_path}"
            rescue
              begin
                execute "cd #{build_root}; tar xf #{local_package} #{name}-#{version} -C #{build_path}"
              rescue
                execute "cd #{build_root}; tar xf #{local_package} -C #{build_path}"
              end
            end
          end

          build_files = ""
          execute "cd #{build_path}; ls" do |type, data|
            build_files = data
          end

          if build_files.split($/).length == 1
            new_package_file = File.basename(build_files.chomp)
            if Package::EXTENSIONS.include?(File.extname(new_package_file))
              execute "mv #{File.join(build_path, new_package_file)} #{build_root}"
              sudo    "rm -rf #{local_package} #{build_path}"
              config.local_package = File.join(build_root, new_package_file)
              
              # Re-execute this proc directly instead of going back through extract() or action_exec()
              detail "Unpacking #{local_package}..."
              instance_exec self, machine, machine.communicate, &EXTRACTOR
            end
          end

        end
      end

      INSTALLER = Proc.new do |package, machine, channel|
        sudo "cd #{build_path}; make install", verbose: true
      end

      PULLER = Proc.new do |package, machine, channel|
        if package_exists?(machine)
          config.local_package = existing_package_file(machine)
          machine.ui.warn "Package #{local_package} already exists, using it for the build. If you would like to re-download the package, you should manually remove it then run `vagrant provision` again."
        else
          source.pull machine, local_package
        end
      end

      def self.new(*args, &block)
        Packages::Base.new(*args, &block)
      end
    end
  end
end

