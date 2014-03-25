require_relative 'user'

module Vagabund
  module Squatter
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :guest_home, :host_home

      DEFAULT_FILES = ['.vimrc', '.viminfo', '.gitconfig', '.ssh/known_hosts']

      def files
        @files ||= DEFAULT_FILES
      end

      def files=(file_arr)
        @files = file_arr
      end

      def file=(filename)
        files << filename
      end

      def host_home
        @host_home ||= File.expand_path('~')
      end 

      def guest_home
        @guest_home ||= '~'
      end

      def user
        @user ||= User.new
      end

    end
  end
end
