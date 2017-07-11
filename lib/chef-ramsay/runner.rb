require 'chef'
require 'chef-ramsay/exceptions'
require 'chef-ramsay/client'
require 'chef-ramsay/logger'
require 'chef-ramsay/server'
require 'chef-ramsay/policyfile/exporter'
require 'chef-ramsay/policyfile/uploader'
require 'chef-ramsay/test/unit'
require 'chef-ramsay/test/integration'

module Ramsay
  class Runner

    include Ramsay::Logger

    attr_reader :cookbook_dir
    attr_reader :policyfile_lock_file
    # TODO: Build the ability to specify a custom policy lock file name.
    def initialize(policyfile_lock_file = nil)
      @cookbook_dir = Dir.pwd
      @policyfile_lock_file = 'Policyfile.lock.json'
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
      @exporter ||= Ramsay::Policyfile::Exporter.new(policyfile_lock_file, cookbook_dir)
    end

    def uploader
      @uploader ||= Ramsay::Policyfile::Uploader.new(policyfile_lock_file)
    end

    def chef_zero_server
      @chef_zero_server ||= Ramsay::Server.new
    end

    def chef_client
      @chef_client ||= Ramsay::Client.new
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
      chef_client.compile
      unit_tester = Ramsay::Test::Unit.new
      integration_tester = Ramsay::Test::Integration.new
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

      puts "\nGenerating a set of unit tests..."
      unit_tester.generate(recipe_resources)
      puts "\nGenerating a set of integration tests..."
      integration_tester.generate(recipe_resources)

    end

  end
end
