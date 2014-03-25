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

      # TODO these should be guest/host OS agnostic
      def host_home
        @host_home ||= File.expand_path('~')
      end 

      def guest_home
        @guest_home ||= '~'
      end

    end
  end
end
