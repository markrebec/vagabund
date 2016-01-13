require 'tmpdir'
require 'json'

module Vagabund
  module Boxer
    class Command < Vagrant.plugin(2, :command)
      def self.synopsis
        "starts, provisions and packages a new vagrant box"
      end

      def initialize(argv, env)
        super
      end

      def execute
        options = Struct.new(:name).new
        
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant boxer [options] [name]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--box-name NAME", "Name the box (and associated AMI for the aws provider)") do |value|
            options.name = value
          end
        end

        argv = parse_options(opts)
        return if !argv
        #raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.empty?

        with_target_vms(argv) do |machine|
          box_name = "#{options.name || machine.name}-#{machine.provider_name}"
          box_file = File.expand_path("./#{box_name}.box")
          
          @env.ui.info "==> #{machine.name}: Packaging box for provider #{machine.provider_name}", bold: true

          if box_exists?(box_file)
            @env.ui.error "The file #{box_file} already exists. Please remove this file or specify a different box name."
            next
          end
          
          if !created?(machine)
            @env.ui.warn "==> #{machine.name}: Can't package VM that hasn't been created. Please create it with `vagrant up` and try again.", bold: true
            next
          end
          
          send "package_#{machine.provider_name.to_s}", machine, box_name
        end

        0
      end

      def status(machine)
        machine.state
      end

      def created?(machine)
        status(machine).id != :not_created
      end

      def stopped?(machine)
        [:poweroff, :stopped].include?(status(machine).id)
      end
      
      def stopping?(machine)
        status(machine).id == :stopping
      end

      def running?(machine)
        status(machine).id == :running
      end

      def package_virtualbox(machine, box_name, box_file=nil)
        box_file ||= File.expand_path("./#{box_name}.box")
        vm_name = machine.config.vm.get_provider_config(:virtualbox).name
        
        if !stopped?(machine)
          @env.ui.warn "==> #{machine.name}: Can't package running VM. Please stop it with `vagrant halt` and try again.", bold: true
          exit
        end

        @env.ui.info "==> #{vm_name || machine.name}: Packaging VirtualBox VM '#{vm_name || machine.name}' into #{File.basename(box_file)}", bold: true

        if vm_name.nil?
          system "vagrant package #{machine.name} --output #{box_file}"
        else
          system "vagrant package --base #{vm_name} --output #{box_file}"
        end
      end

      def package_aws(machine, box_name, box_file=nil)
        box_file ||= File.expand_path("./#{box_name}.box")
          
        if !stopped?(machine)
          if stopping?(machine)
            @env.ui.info "==> #{machine.name}: Waiting for VM to halt...", bold: true
            instance_id = `vagrant awsinfo -m #{machine.name} -k instance_id`.chomp.split($/).last
            wait_for_instance_state(instance_id)
          else
            @env.ui.warn "==> #{machine.name}: Can't package running VM. Please stop it with `vagrant halt` and try again.", bold: true
            exit
          end
        end

        if aws_image_exists?(box_name)
          image_id = existing_image_id(box_name)
          @env.ui.warn "==> #{image_id}: An AMI with the name #{box_name} already exists", bold: true
          @env.ui.warn "    #{image_id}: Using existing AMI to package the box"
        else
          instance_id = `vagrant awsinfo -m #{machine.name} -k instance_id`.chomp.split($/).last
          @env.ui.info "==> #{instance_id}: Packaging AWS instance into AMI #{box_name}...", bold: true
          
          wait_for_instance_state instance_id, 'stopped'
          image_id = `aws ec2 create-image --instance-id=#{instance_id} --name=#{box_name} --output=text`.chomp
        end

        @env.ui.info "==> #{image_id}: Creating AMI #{box_name}...", bold: true
        wait_for_image_state image_id, 'available'
        @env.ui.info "==> #{image_id}: Packaging AMI '#{box_name}' into #{File.basename(box_file)}", bold: true

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            File.write 'Vagrantfile', aws_vagrantfile(image_id, box_name)
            File.write 'metadata.json', aws_metafile
            system "tar cf #{box_file} Vagrantfile metadata.json"
          end
        end
      end

      def box_exists?(box_file)
        File.exists?(box_file)
      end

      def aws_image_exists?(box_name)
        !existing_image_id(box_name).nil?
      end

      def existing_image_id(box_name)
        ami_json = JSON.parse(`aws ec2 describe-images --filters Name=name,Values=#{box_name}`.chomp)
        ami_json['Images'].first['ImageId']
      rescue
        nil
      end
      
      def wait_for_image_state(image_id, state='available')
        @env.ui.info "    #{image_id}: Waiting for image to enter state '#{state}'..."

        last_state = nil 
        while true do
          ami_json = JSON.parse(`aws ec2 describe-images --owners=self --output=json`.chomp)
          image = ami_json['Images'].select { |img| img['ImageId'] == image_id }.first

          if image.nil? # sometimes AWS takes a while to even list the AMI
            @env.ui.info "    #{image_id}: Image is in state '#{image['State']}'" if image['State'] != last_state

            last_state = image['State']
            if image['State'] == 'failed'
              @env.ui.error "==> #{image_id}: Image Creation Failed!", bold: true
              @env.ui.error "    #{image_id}: #{image['StateReason']['Message']}"
              break;
            elsif image['State'] == state
              break;
            end
          else
            @env.ui.info "    #{image_id}: Image is in state 'unknown'" if last_state != 'unknown'
            last_state = 'unknown'
          end
          
          sleep 5
        end 
      end 
      
      def wait_for_instance_state(instance_id, state='stopped')
        # TODO use the machine to check/wait for state instead of `aws`?
        @env.ui.info "    #{instance_id}: Waiting for instance to enter state '#{state}'..."
        
        last_state = nil 
        while true do
          instance_state = JSON.parse(`aws ec2 describe-instances --instance-id=#{instance_id} --output=json --query="Reservations[0].Instances[0].State"`.chomp)
      
          @env.ui.info "    #{instance_id}: Instance is in state '#{instance_state['Name']}'" if instance_state['Name'] != last_state
      
          last_state = instance_state['Name']
          break if instance_state['Name'] == state
          
          sleep 1
        end 
      end

      def aws_vagrantfile(image_id, box_name)
        return <<VAGRANTFILE
Vagrant.configure("2") do |config|
  config.vm.provider :aws do |aws, override|
    aws.ami = "#{image_id}" # #{box_name}
  end
end
VAGRANTFILE
      end

      def aws_metafile
        return <<METAFILE
{
  "provider": "aws"
}
METAFILE
      end

    end
  end
end
