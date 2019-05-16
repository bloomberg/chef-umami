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

require 'chef'
require 'chef-umami/policyfile/policyfile_lock'
require 'tmpdir' # Extends Dir

# NOTE: Lifts some code from https://github.com/chef/chef-dk/blob/master/lib/chef-dk/policyfile_services/export_repo.rb

module Umami
  class Client
    attr_reader :config_path
    attr_reader :policyfile
    attr_reader :staging_dir # Where Umami will stage files.
    def initialize(policyfile = nil)
      @client          = client
      @policy_name     = nil
      @policyfile      = policyfile
      @staging_dir     = Dir.mktmpdir('umami-')
      @config_path     = client_rb_staging_path
    end

    def policy_name
      @policy_name ||= Umami::Policyfile::PolicyfileLock.new(policyfile).name
    end

    def client
      @client ||= Chef::Client.new
    end

    def fake_client_key
      File.join(staging_dir, 'umami.pem')
    end

    def cp_fake_client_key
      # Create a fake client cert based on a dummy cert we have laying around.
      fake_client_key_src = File.join(File.dirname(__FILE__), %w(.. .. support umami.pem))
      FileUtils.cp(fake_client_key_src, fake_client_key)
    end

    def dot_chef_staging_dir
      dot_dir = File.join(staging_dir, '.chef')
      FileUtils.mkdir_p(dot_dir)
      dot_dir
    end

    def client_rb_staging_path
      File.join(dot_chef_staging_dir, 'config.rb')
    end

    def create_client_rb
      File.open(client_rb_staging_path, 'wb+') do |f|
        f.print(<<~CONFIG)
          ### Chef Client Configuration ###
          # The settings in this file will configure chef to apply the exported policy in
          # this directory. To use it, run:
          #
          # chef-client -z
          #
          policy_name '#{policy_name}'
          policy_group 'local'
          use_policyfile true
          policy_document_native_api true
          chef_server_url 'http://127.0.0.1:8889'
          node_name 'umami-node'
          client_key '#{fake_client_key}'
          # In order to use this repo, you need a version of Chef Client and Chef Zero
          # that supports policyfile "native mode" APIs:
          current_version = Gem::Version.new(Chef::VERSION)
          unless Gem::Requirement.new(">= 12.7").satisfied_by?(current_version)
            puts("!" * 80)
            puts(<<-MESSAGE)
          This Chef Repo requires features introduced in Chef 12.7, but you are using
          Chef \#{Chef::VERSION}. Please upgrade to Chef 12.7 or later.
          MESSAGE
            puts("!" * 80)
            exit!(1)
          end
        CONFIG
      end
    end

    def build_config
      create_client_rb
      cp_fake_client_key
    end

    def apply_config!
      build_config
      Chef::Config.from_file(config_path)
      # Define Chef::Config['config_file'] lest Ohai complain.
      Chef::Config['config_file'] = config_path
    end

    # Perform the steps required prior to compiling resources, including
    # running Ohai and building up the node object.
    def prep
      client.run_ohai
      client.load_node # from the server
      client.build_node
    end

    # Execute the compile phase of a Chef client run.
    def compile
      prep
      client.setup_run_context
    end

    # TODO: This can only be called after #prep completes successfully.
    # Add some check to determine if the client is actually prepped.
    def resource_collection
      client.run_status.run_context.resource_collection
    end
  end
end
