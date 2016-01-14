require_relative 'monkey_patches'

module Vagabund
  def self.source_root
    File.expand_path('../../', __FILE__)
  end

  def self.amazon_images(pattern=nil)
    @images ||= JSON.load(`aws ec2 describe-images --owners=self --output=json`)['Images']
    return @images if pattern.nil?
    @images.select { |image| image['Name'].match(pattern) }
  end

  def self.most_recent_ami(pattern)
    amazon_images(pattern).sort { |a,b| DateTime.parse(a['CreationDate']) <=> DateTime.parse(b['CreationDate']) }.last
  end

  class Plugin < Vagrant.plugin(2)
    name "Vagabund"

    # Squatter
    
    config :squat, :provisioner do
      require File.expand_path('../vagabund/squatter/config', __FILE__)
      Squatter::Config
    end

    provisioner :squat do
      require File.expand_path('../vagabund/squatter/provisioner', __FILE__)
      Squatter::Provisioner
    end
    
    
    # Settler

    config :settle, :provisioner do
      require File.expand_path('../vagabund/settler/config', __FILE__)
      Settler::Config
    end

    provisioner :settle do
      require File.expand_path('../vagabund/settler/provisioner', __FILE__)
      Settler::Provisioner
    end

    # Boxer

    command :boxer do
      require File.expand_path('../vagabund/boxer/command', __FILE__)
      Boxer::Command
    end
  end
end

I18n.load_path << File.expand_path("templates/locales/en.yml", Vagabund.source_root)
