module Vagabund
  module Settler
    module Errors
      class SettlerError < Vagrant::Errors::VagrantError
        attr_reader :original_error

        error_namespace "vagabund.settler.errors"

        def message(orig=true)
          return super() if !orig || original_error.nil?
          "#{original_error.class.name}: #{original_error.message}"
        end

        def backtrace(orig=true)
          !orig || original_error.nil? ? super() : original_error.backtrace
        end

        def initialize(*args)
          @original_error = args.shift if args.first.is_a?(Exception)
          super(*args)
        end
      end

      class PackageError < SettlerError; end
      class ProjectError < SettlerError; end

      class PackageBuildError < PackageError
        error_key :package_build_error
      end
      
      class PackageCleanError < PackageError
        error_key :package_clean_error
      end

      class PackageExtractionError < PackageError
        error_key :package_extraction_error
      end
      
      class PackageInstallError < PackageError
        error_key :package_install_error
      end
      
      class PackagePullError < PackageError
        error_key :package_pull_error
      end
    end
  end
end
