require_relative 'errors'
require_relative 'packages/base'

module Vagabund
  module Settler
    module Packages
    end

    class Package < Packages::Base
      EXTENSIONS = ['.gz', '.bz', '.bz2', '.xz', '.zip', '.tar', '.tgz', '.tbz', '.tbz2', '.txz']

      BUILDER = Proc.new do |package, machine, channel|
        channel.execute "cd #{build_path}; ./configure && make"
      end

      CLEANER = Proc.new do |package, machine, channel|
        channel.sudo "rm -rf #{build_root}"
      end

      EXTRACTOR = Proc.new do |package, machine, channel|
        if build_path_exists?(machine)
          machine.ui.warn "Build path #{build_path} already exists, using it for the build. If you would like to use a clean source tree, you should manually remove it and run `vagrant provision` again."
        elsif File.directory?(local_file)
          channel.execute "cp -r #{local_file} #{build_path}" if local_file != build_path
        else
          channel.execute "mkdir -p #{build_path}"
          local_ext = File.extname(local_file)

          case local_ext
          when '.gz'
            channel.execute "cd #{build_root}; gzip -dc #{local_file} > #{build_path}/#{File.basename(local_file, local_ext)}"
          when '.tgz'
            channel.execute "cd #{build_root}; gzip -dc #{local_file} > #{build_path}/#{File.basename(local_file, local_ext)}.tar"
          when '.bz', '.bz2'
            channel.execute "cd #{build_root}; bzip2 -dc #{local_file} > #{build_path}/#{File.basename(local_file, local_ext)}"
          when '.tbz', '.tbz2'
            channel.execute "cd #{build_root}; bzip2 -dc #{local_file} > #{build_path}/#{File.basename(local_file, local_ext)}.tar"
          when '.xz'
            channel.execute "cd #{build_root}; xz -dc #{local_file} > #{build_path}/#{File.basename(local_file, local_ext)}"
          when '.txz'
            channel.execute "cd #{build_root}; xz -dc #{local_file} > #{build_path}/#{File.basename(local_file, local_ext)}.tar"
          when '.zip'
            channel.execute "cd #{build_root}; unzip #{local_file} -d #{build_path}"
            channel.execute("cd #{build_path}; mv #{File.basename(local_file, local_ext)}/* ./") rescue nil
            channel.execute("cd #{build_path}; mv #{File.basename(local_file, local_ext)}/.* ./") rescue nil
            channel.execute("cd #{build_path}; mv #{name}-#{version}/* ./") rescue nil
            channel.execute("cd #{build_path}; mv #{name}-#{version}/.* ./") rescue nil
            channel.execute("cd #{build_path}; rm -rf #{File.basename(local_file, local_ext)}") rescue nil
          when '.tar'
            begin
              channel.execute "cd #{build_root}; tar xf #{local_file} #{File.basename(local_file, local_ext)} -C #{build_path}"
            rescue
              begin
                channel.execute "cd #{build_root}; tar xf #{local_file} #{name}-#{version} -C #{build_path}"
              rescue
                channel.execute "cd #{build_root}; tar xf #{local_file} -C #{build_path}"
              end
            end
          end

          build_files = ""
          channel.execute "cd #{build_path}; ls" do |type, data|
            build_files = data
          end

          if build_files.split($/).length == 1
            new_package_file = File.basename(build_files.chomp)
            if Package::EXTENSIONS.include?(File.extname(new_package_file))
              channel.execute "mv #{File.join(build_path, new_package_file)} #{build_root}"
              channel.sudo    "rm -rf #{local_file} #{build_path}"
              config.local_file = File.join(build_root, new_package_file)
              extract(machine)
            end
          end

        end
      end

      INSTALLER = Proc.new do |package, machine, channel|
        channel.sudo "cd #{build_path}; make install"
      end

      PULLER = Proc.new do |package, machine, channel|
        if package_exists?(machine)
          config.local_file = existing_package_file(machine)
          machine.ui.warn "Package #{local_file} already exists, using it for the build. If you would like to re-download the package, you should manually remove it then run `vagrant provision` again."
        else
          source.pull machine, local_file
        end
      end

      def self.new(*args, &block)
        Packages::Base.new(*args, &block)
      end
    end
  end
end

