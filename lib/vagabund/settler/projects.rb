require_relative 'errors'
require_relative 'projects/base'
require_relative 'projects/ruby'
require_relative 'projects/rails'

module Vagabund
  module Settler
    module Projects
    end

    class Project < Projects::Base
      def self.new(*args, &block)
        klass = (args.first.is_a?(Symbol) ? args.shift : :base).to_s.capitalize
        eval("Projects::#{klass}.new *args, &block")
      end
    end
  end
end

