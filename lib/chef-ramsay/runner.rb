require 'chef'
require 'chef-ramsay/exceptions'
require 'chef-ramsay/client'
require 'chef-ramsay/logger'
require 'chef-ramsay/server'
require 'chef-ramsay/policyfile/exporter'
require 'chef-ramsay/policyfile/uploader'
require 'chef-ramsay/test/unit'

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
      exporter.export
      Chef::Config.from_file("#{exporter.chef_config_file}")
      chef_zero_server.start
      uploader.upload
      chef_client.prep
      unit_tester = Ramsay::Test::Unit.new
      p unit_tester
      recipe_resources = {}
      chef_client.resource_collection.each do |resource|
        canonical_recipe = "#{resource.cookbook_name}::#{resource.recipe_name}"
        if recipe_resources.key?(canonical_recipe)
          recipe_resources[canonical_recipe] << resource
        else
          recipe_resources[canonical_recipe] = [resource]
        end
        #puts "\nRESOURCE: '#{resource.to_s}'"
        #puts "NAME:     '#{resource.name}'"
        #puts "TYPE:     '#{resource.class}'"
        #puts "ACTION:   '#{resource.action.to_s}'"
        #puts "FROM:     '#{resource.cookbook_name}::#{resource.recipe_name}'"
        #p resource.state
      end

      # TODO: The below code with go into it's own class.
      puts "\n\n\n\n\n\n"
      recipe_resources.each do |recipe, resources|
        (cookbook, recipe) = recipe.split('::')
        puts "# spec/unit/#{cookbook}/#{recipe}_spec.rb"
        puts
        puts "require 'chefspec'"
        puts
        puts "describe '#{recipe}' do"
        puts "  let(:chef_run) { ChefSpec::ServerRunner.converge(described_recipe) }"
        resources.each do |resource|
          puts "  "
          puts "  it '#{resource.action.first}s #{resource.declared_type} \"#{resource.name}\"' do"
          puts "    expect(chef_run).to #{resource.action.first}_#{resource.declared_type}('#{resource.name}')"
          state_attrs = resource.state.keys.map {|attr| ":#{attr}"}.join(', ')
          puts "    expect(resource).to have_state_attrs(#{state_attrs})"
          puts "  end"
          #p "#{resource.name}: #{resource.state}" # We need this info to generate tests re: resource state.
        end
        puts "end"
      end

    end

  end
end
