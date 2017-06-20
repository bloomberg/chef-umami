#!/opt/chefdk/embedded/bin/ruby # Mac OSX
####!/opt/chef/embedded/bin/ruby # Linux

# ramsay

require 'chef'
require 'chef_zero/server'
require 'chef-dk/authenticated_http'
require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile/uploader'
require 'chef-dk/policyfile_lock'
require 'chef-dk/policyfile_services/export_repo'
require 'chef-dk/ui'
require 'fileutils'
require 'tmpdir' # Extends Dir.

policyfile_lock_file = 'Policyfile.lock.json'
unless File.exist?(policyfile_lock_file)
  puts
  puts '!' * 50
  puts "Unable to locate '#{policyfile_lock_file}'!"
  puts 'You may need to run `chef install` to generate it.'
  puts '!' * 50
  puts
  exit 1
end

# Export the cookbook and prepare a chef-zero-compatible directory.
# We'll use this as a temporary launch pad for things, as needed, akin
# to test-kitchen's sandbox.
cookbook_dir = File.basename(Dir.pwd)
export_root = Dir.mktmpdir('ramsay-')
# We need the target dir named the same as the source dir so that `chef` commands
# work as happily programatically as they would via the command line.
# This is because the commands assume they're being run from within a cookbook
# directory.
export_path = File.join(export_root, cookbook_dir)
puts
puts "#" * 20
puts "Exporting #{cookbook_dir} to #{export_path}..."
puts "#" * 20
export_service = ChefDK::PolicyfileServices::ExportRepo.new(
  policyfile: policyfile_lock_file,
  export_dir: export_path
)
export_service.run

chef_config_file = "#{export_path}/.chef/config.rb"
puts "#" * 20
puts "Updating the Chef client config at #{chef_config_file}"
puts "#" * 20
# Create a fake client cert based on a dummy cert we have laying around.
fake_client_key = "#{export_path}/ramsay.pem"
fake_client_key_src = File.join(File.dirname(__FILE__), %w(support ramsay.pem))
FileUtils.cp(fake_client_key_src, fake_client_key)

File.open(chef_config_file, 'a') do |f|
  f.puts "chef_server_url 'http://127.0.0.1:8889'"
  f.puts "cookbook_path ['#{export_path}/cookbook_artifacts']"
  f.puts "client_key '#{fake_client_key}'"
  f.puts "node_name 'ramsay-node'"
end
# Import the client config.
Chef::Config.from_file("#{export_path}/.chef/config.rb")

# Run our own chef-zero instance and use the cookbooks in the sandbox to
# enumerate the resources.
server = ChefZero::Server.new(port: 8889)
server.start_background

# Instantiate a Chef::Client object.
client = Chef::Client.new

# Push the policy, including all dependent cookbooks.
puts
puts "#" * 20
puts "Uploading policyfile '#{policyfile_lock_file}' and related cookbooks..."
puts "#" * 20
storage_config = ChefDK::Policyfile::StorageConfig.new.use_policyfile(policyfile_lock_file)
ui = ChefDK::UI.new
policyfile_lock_content = IO.read(policyfile_lock_file)
lock_data = FFI_Yajl::Parser.new.parse(policyfile_lock_content)
policyfile_lock = ChefDK::PolicyfileLock.new(
  storage_config,
  ui: ui
).build_from_lock_data(lock_data)
http_client = ChefDK::AuthenticatedHTTP.new(Chef::Config['chef_server_url'])
policy_group = Chef::Config['policy_group']
policy_document_native_api = true
policyfile_uploader = ChefDK::Policyfile::Uploader.new(
  policyfile_lock,
  policy_group,
  ui: ui,
  http_client: http_client,
  policy_document_native_api: policy_document_native_api
)
policyfile_uploader.upload_policy # Just the policy
policyfile_uploader.upload
puts "Policyfile upload complete"

puts
puts "#" * 20
puts "Running chef-client..."
puts "#" * 20
# Get node information, including node_name, required to get/build node info;
# test afterward with `client.node_name`
client.run_ohai
client.load_node # from the server
client.build_node
client.setup_run_context # /me crosses fingers
my_resources = {}
recipe_resources = {}
client.run_status.run_context.resource_collection.each do |resource|
  ## Check for dupe resources? Or will Chef merge them during compile time?
  #if my_resources.has_key?(resource.to_s)
  #  my_resources[resource.to_s] += 1
  #else
  #  my_resources[resource.to_s] = 1
  #end
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

def test_directory(name)
  "  describe file('#{name}') do\n    it { should be_directory }\n  end"
end

def test_package(name)
  "  describe package('#{name}') do\n    it { should be_installed }\n  end"
end

puts "\n\n\n"
recipe_resources.each do |recipe, resources|
  (cookbook, recipe) = recipe.split('::')
  puts "# spec/integration/#{cookbook}/#{recipe}_spec.rb"
  puts
  puts "require 'serverspec'"
  resources.each do |resource|
    puts "  "
    puts send("test_#{resource.declared_type}", resource.name)
    #puts "  describe #{resource.declared_type}('#{resource.name}') do"
    #puts "    it { should do_something_appropriate_for_this_resource }"
    #puts "  end"
    #p "#{resource.name}: #{resource.state}" # We need this info to generate tests re: resource state.
  end
  puts "end"
end
puts "\n\n\n\n\n\n"

# TODO:
# 1. Ensure we shut down chef-zero (i.e. via at_exit)
# 2. Clean up the temp directory.

