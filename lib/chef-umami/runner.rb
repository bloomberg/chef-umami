#   Copyright 2017 Bloomberg, L.P.
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
require 'chef-umami/exceptions'
require 'chef-umami/client'
require 'chef-umami/logger'
require 'chef-umami/server'
require 'chef-umami/policyfile/exporter'
require 'chef-umami/policyfile/uploader'
require 'chef-umami/test/unit'
require 'chef-umami/test/integration'

module Umami
  class Runner

    include Umami::Logger

    attr_reader :cookbook_dir
    attr_reader :policyfile_lock_file
    attr_reader :policyfile
    # TODO: Build the ability to specify a custom policy lock file name.
    def initialize(policyfile_lock_file = nil, policyfile = nil)
      @cookbook_dir = Dir.pwd
      @policyfile_lock_file = 'Policyfile.lock.json'
      @policyfile = policyfile || 'Policyfile.rb'
      @exporter = exporter
      @chef_zero_server = chef_zero_server
      # If we load the uploader or client now, they won't see the updated
      # Chef config!
      @uploader = nil
      @chef_client = nil
    end

    def validate_lock_file!
      unless policyfile_lock_file.end_with?("lock.json")
        raise InvalidPolicyfileLockFilename, "Policyfile lock files must end in '.lock.json'. I received '#{policyfile_lock_file}'."
      end

      unless File.exist?(policyfile_lock_file)
        raise InvalidPolicyfileLockFilename, "Unable to locate '#{policyfile_lock_file}' You may need to run `chef install` to generate it."
      end
    end

    def exporter
      @exporter ||= Umami::Policyfile::Exporter.new(policyfile_lock_file, cookbook_dir, policyfile)
    end

    def uploader
      @uploader ||= Umami::Policyfile::Uploader.new(policyfile_lock_file)
    end

    def chef_zero_server
      @chef_zero_server ||= Umami::Server.new
    end

    def chef_client
      @chef_client ||= Umami::Client.new
    end

    def run
      validate_lock_file!
      puts "\nExporting the policy, related cookbooks, and a valid client configuration..."
      exporter.export
      Chef::Config.from_file("#{exporter.chef_config_file}")
      chef_zero_server.start
      puts "\nUploading the policy and related cookbooks..."
      uploader.upload
      puts "\nExecuting chef-client compile phase..."
      # Define Chef::Config['config_file'] lest Ohai complain.
      Chef::Config['config_file'] = exporter.chef_config_file
      chef_client.compile
      # Build a hash of all the recipes' resources, keyed by the canonical
      # name of the recipe (i.e. ohai::default).
      recipe_resources = {}
      chef_client.resource_collection.each do |resource|
        canonical_recipe = "#{resource.cookbook_name}::#{resource.recipe_name}"
        if recipe_resources.key?(canonical_recipe)
          recipe_resources[canonical_recipe] << resource
        else
          recipe_resources[canonical_recipe] = [resource]
        end
      end

      # Remove the temporary directory using a naive guard to ensure we're
      # deleting what we expect.
      re_export_path = Regexp.new('/tmp/umami')
      FileUtils.rm_rf(exporter.export_root) if exporter.export_root.match(re_export_path)

      puts "\nGenerating a set of unit tests..."
      unit_tester = Umami::Test::Unit.new
      unit_tester.generate(recipe_resources)

      puts "\nGenerating a set of integration tests..."
      integration_tester = Umami::Test::Integration.new
      integration_tester.generate(recipe_resources)

    end

  end
end
