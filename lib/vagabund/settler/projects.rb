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
        Projects::Base.new(*args, &block)
      end
    end
  end
end

