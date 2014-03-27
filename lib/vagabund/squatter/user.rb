module Vagabund
  module Squatter
    class User
      attr_accessor :username, :password, :home, :shell, :group, :groups, :sudo, :public_key, :ssh_config

      def home
        @home || "/home/#{username}"
      end

      def shell
        @shell ||= "/bin/bash"
      end

      def pubkeys
        unless @public_key.nil?
          [@public_key].flatten.map do |pubkey|
            begin
              File.read(File.expand_path(pubkey)).chomp
            rescue Exception => e
              pubkey
            end
          end.join($/)
        end
      end

      def ssh_conf_str
        unless @ssh_config.nil?
          begin
            File.read(File.expand_path(@ssh_config)).chomp
          rescue Exception => e
            @ssh_config
          end
        end
      end

      def to_s
        cmd_str = "useradd -m -s #{shell}"
        cmd_str += " -d #{home}"
        cmd_str += " -g #{group}" unless group.nil?
        cmd_str += " -G #{[groups].flatten.join(',')}" unless groups.nil?
        cmd_str += " #{username}"
      end

      def create?
        !username.nil?
      end

      protected

      def initialize
        @sudo = true
      end

    end
  end
end
