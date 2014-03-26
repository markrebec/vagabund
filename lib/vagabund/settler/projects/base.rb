require_relative 'project_config'

module Vagabund
  module Settler
    module Projects
      class Base
        attr_reader :config

        def provision(machine)
          exec_before :project, machine
          pull machine
          exec_after :project, machine
        end

        def pull(machine)
          exec_before :pull, machine
          if config.puller.nil?
            config.source.pull machine, project_path
          else
            action_exec config.puller, machine
          end
          exec_after :pull, machine
        rescue StandardError => e
          raise Settler::Errors::ProjectError, e
        end
        
        def exec_before(action, machine)
          hook_exec :before, action, machine
        end

        def exec_after(action, machine)
          hook_exec :after, action, machine
        end

        def hook_exec(hook, action, machine)
          hook_action = "#{hook.to_s}_#{action.to_s.gsub(/[eo]r$/, '')}"
          return if config.send(hook_action).nil? || config.send(hook_action).empty?

          machine.ui.detail "Executing custom :#{hook_action} hooks for project #{name}..."
          config.send(hook_action).each do |hact|
            action_exec hact, machine
          end
        rescue StandardError => e
          raise Settler::Errors::ProjectError, e
        end

        def action_exec(command, machine)
          self.class.instance_eval do
            [:ask, :detail, :error, :info, :output, :warn].each do |cmd|
              define_method cmd do |*args, &block|
                machine.ui.send cmd, *args, &block
              end
            end
            [:execute, :sudo, :test].each do |cmd|
              define_method cmd do |*args, &block|
                opts = {verbose: false}.merge(args.extract_options!)
                if opts[:verbose] == true
                  machine.communicate.send cmd, *args, opts do |type,data|
                    color = type == :stderr ? :red : :green
                    options = {
                      color: color,
                      new_line: false,
                      prefix: false
                    }

                    detail(data, options)
                    block.call(type, data) unless block.nil?
                  end
                else
                  machine.communicate.send cmd, *args, opts, &block
                end
              end
            end
          end

          instance_exec self, machine, machine.communicate, &command if command.is_a?(Proc)

          self.class.instance_eval do
            [:ask, :detail, :error, :info, :output, :warn, :execute, :sudo, :test].each do |cmd|
              undef_method cmd
            end
          end
        end
        
        def configure(&block)
          config.configure &block
        end

        def name
          config.name
        end

        def project_path
          config.project_path
        end

        protected

        #
        # Base.new 'my_project', {git: 'git@github.com:/user/repo.git'}
        #
        def initialize(*args, &block)
          opts = args.extract_options!
          opts = {name: args.shift}.merge(opts)
          @config = ProjectConfig.new(opts, &block)
        end

      end
    end
  end
end
