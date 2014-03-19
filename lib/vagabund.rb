module Vagabund
  class Plugin < Vagrant.plugin(2)
    name "Vagabund"

    config :dotfiles, :provisioner do
      require File.expand_path('../vagabund/dotfiles/config', __FILE__)
      Dotfiles::Config
    end

    provisioner :dotfiles do
      require File.expand_path('../vagabund/dotfiles/provisioner', __FILE__)
      Dotfiles::Provisioner
    end
  end
end
