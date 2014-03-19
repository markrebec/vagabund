module Vagabund
  module Dotfiles
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def provision
        config.dotfiles.each do |dotfile|
          from, to = expanded_paths(dotfile)

          unless File.exists?(from)
            @machine.ui.warn "Config file #{from} does not exist. Skipping."
            next
          end

          upload from, to
        end
      end

      protected

      def expanded_paths(dotfile)
        if dotfile.is_a?(Array) # separate source and destination, both expanded relative to home if not absolute
          from = Pathname.new(dotfile[0]).absolute? ? dotfile[0] : File.expand_path(File.join(config.host_home, dotfile[0]))
          to = Pathname.new(dotfile[1]).absolute? ? dotfile[1] : File.expand_path(File.join(config.host_home, dotfile[1]))
        elsif Pathname.new(dotfile).absolute? # already absolute
          from = to = dotfile
        else # expand path relative to home
          from = File.expand_path(File.join(config.host_home, dotfile))
          to = File.expand_path(File.join(config.guest_home, dotfile))
        end

        [from, to]
      end

      def upload(from, to)
        begin
          @machine.communicate.execute "mkdir -p #{File.dirname(to)}" # TODO this should be guest OS agnostic
          @machine.communicate.upload from, to
          @machine.ui.success "Uploaded config file #{from} to #{to}"
        rescue Vagrant::Errors::VagrantError => e
          @machine.ui.error "Failed to upload config file #{from} to #{to}"
          raise e
        end
      end

    end
  end
end
