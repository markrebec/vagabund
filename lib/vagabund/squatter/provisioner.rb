module Vagabund
  module Squatter
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
        @root_config = root_config
      end

      def provision
        create_user
        upload_files
      end

      def cleanup
        # remove the user?
        super
      end

      def create_user
        if config.user.create?
          if @machine.communicate.test "[ `getent passwd | grep -c '^#{config.user.username}:'` == 0 ]"
            @machine.ui.info "Creating user #{config.user.username}..."
            @machine.communicate.sudo config.user.to_s

            # Copy over the authorized_keys and known_hosts files being used currently for compatibility
            if !@machine.communicate.test "[ -d #{config.user.home}/.ssh ]"
              ssh_user_home = ''
              @machine.communicate.execute "echo $HOME" do |type,data|
                ssh_user_home = data.chomp if type == :stdout
              end
              
              @machine.communicate.sudo "mkdir -p #{config.user.home}/.ssh"
              
              if config.user.pubkeys.nil?
                # Copy the authorized_keys file if it doesn't exist and no public keys were provided
                if !@machine.communicate.test("[ -f #{config.user.home}/.ssh/authorized_keys ]") && @machine.communicate.test("[ -f #{ssh_user_home}/.ssh/authorized_keys ]")
                  @machine.communicate.sudo "cp #{ssh_user_home}/.ssh/authorized_keys #{config.user.home}/.ssh/authorized_keys"
                end
              else
                # Add the public key(s) provided
                @machine.communicate.sudo "echo \"#{config.user.pubkeys}\" > #{config.user.home}/.ssh/authorized_keys"
              end

              unless config.user.ssh_conf_str.nil?
                @machine.communicate.sudo "echo \"#{config.user.ssh_conf_str}\" > #{config.user.home}/.ssh/config", verbose: true
              end
              
              if !@machine.communicate.test("[ -f #{config.user.home}/.ssh/known_hosts ]") && @machine.communicate.test("[ -f #{ssh_user_home}/.ssh/known_hosts ]")
                @machine.communicate.sudo "cp #{ssh_user_home}/.ssh/known_hosts #{config.user.home}/.ssh/known_hosts"
              end
              
              @machine.communicate.sudo "chown -R #{config.user.username} #{config.user.home}/.ssh"
              @machine.communicate.sudo "chgrp -R #{config.user.username} #{config.user.home}/.ssh"
            end

            # Add to sudoers
            if config.user.sudo
              @machine.communicate.sudo "echo \"#{config.user.username} ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/#{config.user.username}"
              @machine.communicate.sudo "chmod 0440 /etc/sudoers.d/#{config.user.username}"
            end
          else
            @machine.ui.warn "User #{config.user.username} already exists"
          end
            
        end
      rescue
        @machine.ui.error "Failed to create user #{config.user.username}"
        @machine.communicate.sudo "userdel -r forthrail" rescue nil
        @machine.communicate.sudo "rm -rf /etc/sudoers.d/#{config.user.username}"
      end

      def upload_files
        config.files.each do |file|
          sync *expanded_paths(file)
        end
      end

      protected

      def guest_home
        gh_path = config.guest_home
        @machine.communicate.execute "cd #{gh_path}; pwd" do |type, data|
          gh_path = data.chomp if type == :stdout
        end
        gh_path
      end

      def host_home
        File.expand_path(config.host_home)
      end

      def expanded_paths(file)
        # separate source and destination, both expanded relative to home if not absolute
        if file.is_a?(Array)
          from = expanded_paths(file[0])[0]
          to = expanded_paths(file[1])[1]

        # remote source file
        elsif file.match(/^(http[s]?|s3):\/\//i)
          from = file
          to = File.join(guest_home, File.basename(file))

        # already absolute
        elsif Pathname.new(file).absolute?
          from = to = file

        # expand path relative to home
        else
          from = File.join(host_home, file)
          to = File.join(guest_home, file)
        end

        [from, to]
      end

      def sync(from, to)
        if from.match(/^(http[s]?|s3):\/\//i)
          @machine.ui.detail "Downloading #{from}..."
          Dir.mktmpdir do |dir|
            from_file = File.join(dir, File.basename(from))

            if from.match(/^http[s]?:\/\//i)
              `curl -L -o #{from_file} #{from} 2>&1`
            elsif from.match(/^s3:\/\//i)
              `aws s3 cp #{from} #{from_file}`
            end

            upload from_file, to
          end
        else
          unless File.exists?(from)
            @machine.ui.warn "Local file #{from} does not exist. Skipping."
            return
          end
          upload from, to
        end
      end

      def upload(from, to)
        begin
          @machine.ui.detail "Uploading #{from} to #{to}..."
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
