#   Copyright 2017 Bloomberg Finance, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'chef-dk/policyfile_services/install'
require 'chef-dk/policyfile_services/export_repo'
require 'chef-dk/ui'
require 'tmpdir' # Extends Dir

module Umami
  class Policyfile
    class Exporter

      attr_reader   :chef_config_file
      attr_reader   :cookbook_dir
      attr_reader   :export_root
      attr_reader   :export_path
      attr_accessor :policyfile_lock_file
      attr_reader   :policyfile

      def initialize(policyfile_lock_file = nil, cookbook_dir = nil, policyfile = nil)
        @policyfile = policyfile
        @export_root = Dir.mktmpdir('umami-')
        # We need the target dir named the same as the source dir so that `chef` commands
        # work as happily programatically as they would via the command line.
        # This is because the commands assume they're being run from within a cookbook
        # directory.
        @export_path = File.join(export_root, cookbook_dir)
        @chef_config_file = "#{export_path}/.chef/config.rb"
      end

      def policyfile
        @policyfile
      end

      def ui
        @ui ||= ChefDK::UI.new
      end

      # Execute `chef install` to ensure we get a fresh, clean Policyfile lock
      # file on each run.
      def install_policy
        puts "Generating a new Policyfile from '#{policyfile}'..."
        install_service = ChefDK::PolicyfileServices::Install.new(
          policyfile: policyfile,
          ui: ui
        )
        @policyfile_lock_file = install_service.storage_config.policyfile_lock_filename
        install_service.run
      end

      def fake_client_key
        "#{export_path}/umami.pem"
      end

      def cp_fake_client_key
        # Create a fake client cert based on a dummy cert we have laying around.
        fake_client_key_src = File.join(File.dirname(__FILE__), %w(.. .. .. support umami.pem))
        FileUtils.cp(fake_client_key_src, fake_client_key)
      end

      def update_chef_config
        File.open(chef_config_file, 'a') do |f|
          f.puts "chef_server_url 'http://127.0.0.1:8889'"
          f.puts "cookbook_path ['#{export_path}/cookbook_artifacts']"
          f.puts "client_key '#{fake_client_key}'"
          f.puts "node_name 'umami-node'"
        end
      end

      # Export the cookbook and prepare a chef-zero-compatible directory.
      # We'll use this as a temporary launch pad for things, as needed, akin
      # to test-kitchen's sandbox.
      def export
        install_policy
        export_service = ChefDK::PolicyfileServices::ExportRepo.new(
          policyfile: policyfile_lock_file,
          export_dir: export_path
        )
        begin
          export_service.run
        rescue ChefDK::PolicyfileExportRepoError => e
          puts "\nFAILED TO EXPORT POLICYFILE: #{e.message} (#{e.class})"
          puts "CAUSE: #{e.cause}"
          puts "BACKTRACE:"
          e.backtrace.each do |line|
            puts "\t#{line}"
          end
          exit(1)
        end
        cp_fake_client_key
        update_chef_config
      end

    end
  end
end
