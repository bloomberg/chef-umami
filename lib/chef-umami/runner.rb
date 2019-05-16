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
require 'chef-umami/exceptions'
require 'chef-umami/client'
require 'chef-umami/logger'
require 'chef-umami/options'
require 'chef-umami/server'
require 'chef-umami/policyfile_services/push'
require 'chef-umami/test/unit'
require 'chef-umami/test/integration'
require 'chef-dk/ui'

module Umami
  class Runner
    include Umami::Logger
    include Umami::Options

    attr_reader :cookbook_dir
    def initialize
      @umami_config = umami_config
      @cookbook_dir = Dir.pwd
      ## If we load the pusher or client now, they won't see the updated
      ## Chef config!
      @push = nil
      @chef_client = nil
      @ui = ui
    end

    # A hash of values describing the Umami config. Comprised of command line
    # options. May (in the future) contain options read from a config file.
    def umami_config
      @umami_config ||= parse_options
    end

    # Convenience to return the Chef::Config singleton.
    def chef_config
      Chef::Config
    end

    def ui
      @ui ||= ChefDK::UI.new
    end

    def policyfile
      umami_config[:policyfile]
    end

    def policy_group
      chef_config['policy_group']
    end

    # Return the computed policyfile lock name.
    def policyfile_lock_file
      policyfile.gsub(/\.rb$/, '.lock.json')
    end

    def validate_lock_file!
      unless policyfile_lock_file.end_with?('lock.json')
        raise InvalidPolicyfileLockFilename, "Policyfile lock files must end in '.lock.json'. I received '#{policyfile_lock_file}'."
      end

      unless File.exist?(policyfile_lock_file)
        raise InvalidPolicyfileLockFilename, "Unable to locate '#{policyfile_lock_file}' You may need to run `chef install` to generate it."
      end
    end

    def push
      # rubocop:disable Layout/AlignHash
      @push ||= Umami::PolicyfileServices::Push.new(policyfile: policyfile,
                                                      ui:           ui,
                                                      policy_group: policy_group,
                                                      config:       chef_config,
                                                      root_dir:     cookbook_dir)
      # rubocop:enable Layout/AlignHash
    end

    def chef_zero_server
      @chef_zero_server ||= Umami::Server.new
    end

    def chef_client
      @chef_client ||= Umami::Client.new(policyfile)
    end

    def run
      validate_lock_file!
      chef_client.apply_config!
      chef_zero_server.start
      puts "\nUploading the policy and related cookbooks..."
      push.run
      puts "\nExecuting chef-client compile phase..."
      chef_client.compile
      # Build a hash of all the recipes' resources, keyed by the canonical
      # name of the recipe (i.e. ohai::default).
      recipe_resources = {}
      chef_client.resource_collection.each do |resource|
        canonical_recipe = "#{resource.cookbook_name}::#{resource.recipe_name}"
        unless umami_config[:recipes].nil? || umami_config[:recipes].empty?
          # The user has explicitly requested that one or more recipes have
          # tests written, to the exclusion of others.
          # ONLY include the recipe if it matches the list.
          next unless umami_config[:recipes].include?(canonical_recipe)
        end
        if recipe_resources.key?(canonical_recipe)
          recipe_resources[canonical_recipe] << resource
        else
          recipe_resources[canonical_recipe] = [resource]
        end
      end

      # Remove the temporary directory using a naive guard to ensure we're
      # deleting what we expect.
      re_export_path = Regexp.new('/tmp/umami')
      FileUtils.rm_rf(chef_client.staging_dir) if chef_client.staging_dir.match(re_export_path)

      if umami_config[:unit_tests]
        puts "\nGenerating a set of unit tests..."
        unit_tester = Umami::Test::Unit.new(umami_config[:test_root])
        unit_tester.generate(recipe_resources)
      end

      if umami_config[:integration_tests]
        puts "\nGenerating a set of integration tests..."
        integration_tester = Umami::Test::Integration.new(umami_config[:test_root])
        integration_tester.generate(recipe_resources)
      end
    end
  end
end
