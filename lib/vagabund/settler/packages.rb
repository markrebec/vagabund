require_relative 'packages/base'

module Vagabund
  module Settler
    module Packages
    end

    class Package < Packages::Base
      def self.new(*args, &block)
        Packages::Base.new(*args, &block)
      end
    end
  end
end

