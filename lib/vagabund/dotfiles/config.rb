module Vagabund
  module Dotfiles
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :guest_home, :host_home

      DEFAULT_DOTFILES = ['.vimrc', '.viminfo', '.gitconfig', '.ssh/known_hosts']

      def dotfiles
        @dotfiles ||= DEFAULT_DOTFILES
      end
      alias_method :files, :dotfiles

      def dotfiles=(file_arr)
        @dotfiles = file_arr
      end
      alias_method :files=, :dotfiles=

      def file=(filename)
        dotfiles << filename
      end

      # TODO these should be guest/host OS agnostic
      def host_home
        @host_home ||= File.expand_path('~')
      end 

      def guest_home
        @guest_home ||= '/home/vagrant'
      end

    end
  end
end
