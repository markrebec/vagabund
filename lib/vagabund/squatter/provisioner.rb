module Vagabund
  module Squatter
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def provision
        config.files.each do |file|
          from, to = expanded_paths(file)

          unless File.exists?(from)
            @machine.ui.warn "Config file #{from} does not exist. Skipping."
            next
          end

          upload from, to
        end
      end

      protected

      def expanded_paths(file)
        if file.is_a?(Array) # separate source and destination, both expanded relative to home if not absolute
          from = Pathname.new(file[0]).absolute? ? file[0] : File.expand_path(File.join(config.host_home, file[0]))
          to = Pathname.new(file[1]).absolute? ? file[1] : File.expand_path(File.join(config.host_home, file[1]))
        elsif Pathname.new(file).absolute? # already absolute
          from = to = file
        else # expand path relative to home
          from = File.expand_path(File.join(config.host_home, file))
          to = File.expand_path(File.join(config.guest_home, file))
        end

        [from, to]
      end

      def upload(from, to)
        begin
          @machine.ui.info "Uploading #{from} to #{to}..."
          @machine.communicate.execute "mkdir -p #{File.dirname(to)}" # TODO this should be guest OS agnostic
          @machine.communicate.upload from, to
        rescue Vagrant::Errors::VagrantError => e
          @machine.ui.error "Failed to upload config file #{from} to #{to}"
          raise e
        end
      end

    end
  end
end
