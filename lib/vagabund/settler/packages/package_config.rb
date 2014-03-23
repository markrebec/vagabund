module Vagabund
  module Settler
    module Packages
      class PackageConfig
        attr_reader :config
        
        %w(builder cleaner extractor installer puller).each do |action|
          define_method action.to_sym do |*args, &block|
            if args.first.is_a?(String)
              command = args.shift
              opts = args.extract_options!

              cmd_proc = Proc.new do |package, machine, channel|
                opts[:sudo] ? channel.sudo(command) : channel.execute(command)
              end
              
              config.send "#{action}=".to_sym, cmd_proc
            end
            
            config.send "#{action}=".to_sym, args.shift if !args.empty? && (args.first.nil? || args.first.is_a?(Proc))
            config.send "#{action}=".to_sym, block if !block.nil? # block_given? doesn't work here
            config.send action.to_sym
          end
          alias_method "#{action}=".to_sym, action.to_sym
          alias_method "#{action.gsub(/[eo]r$/, '')}_with".to_sym, action.to_sym
        end
        
        def configure(&block)
          instance_eval &block if block_given?
        end

        def method_missing(meth, *args, &block)
          config.send meth, *args, &block
        end

        def respond_to_missing?(meth, include_private=false)
          config.respond_to? meth, include_private
        end

        protected

        def initialize(*args, &block)
          @config = OpenStruct.new({builder: Package::BUILDER, cleaner: Package::CLEANER, extractor: Package::EXTRACTOR, installer: Package::INSTALLER, puller: Package::PULLER}.merge(args.extract_options!))
          configure &block if block_given?
        end
      end
    end
  end
end
