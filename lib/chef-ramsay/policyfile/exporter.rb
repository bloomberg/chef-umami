require 'chef-dk/policyfile_services/export_repo'
require 'tmpdir' # Extends Dir

module Ramsay
  class Policyfile
    class Exporter

			attr_reader :chef_config_file
      attr_reader :cookbook_dir
    	attr_reader :export_root
    	attr_reader :export_path
      attr_reader :policyfile_lock_file

      def initialize(policyfile_lock_file = nil, cookbook_dir = nil)
      	@export_root = Dir.mktmpdir('ramsay-')
      	# We need the target dir named the same as the source dir so that `chef` commands
      	# work as happily programatically as they would via the command line.
      	# This is because the commands assume they're being run from within a cookbook
      	# directory.
      	@export_path = File.join(export_root, cookbook_dir)
				@chef_config_file = "#{export_path}/.chef/config.rb"
      end

			def fake_client_key
        "#{export_path}/ramsay.pem"
			end

      def cp_fake_client_key
        # Create a fake client cert based on a dummy cert we have laying around.
        fake_client_key_src = File.join(File.dirname(__FILE__), %w(.. .. .. support ramsay.pem))
        FileUtils.cp(fake_client_key_src, fake_client_key)
      end

      def update_chef_config
        File.open(chef_config_file, 'a') do |f|
          f.puts "chef_server_url 'http://127.0.0.1:8889'"
          f.puts "cookbook_path ['#{export_path}/cookbook_artifacts']"
          f.puts "client_key '#{fake_client_key}'"
          f.puts "node_name 'ramsay-node'"
        end
      end

	    # Export the cookbook and prepare a chef-zero-compatible directory.
	    # We'll use this as a temporary launch pad for things, as needed, akin
	    # to test-kitchen's sandbox.
      def export
				export_service = ChefDK::PolicyfileServices::ExportRepo.new(
				  policyfile: policyfile_lock_file,
				  export_dir: export_path
				)
				export_service.run
        cp_fake_client_key
        update_chef_config
      end

    end
  end
end
