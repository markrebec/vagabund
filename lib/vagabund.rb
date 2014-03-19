module Vagabund
  class Plugin < Vagrant.plugin(2)
    name "Vagabund"

    config :squat, :provisioner do
      require File.expand_path('../vagabund/squatter/config', __FILE__)
      Squatter::Config
    end

    provisioner :squat do
      require File.expand_path('../vagabund/squatter/provisioner', __FILE__)
      Squatter::Provisioner
    end
  end
end
