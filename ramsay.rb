#!/opt/chef/embedded/bin/ruby

# ramsay
# Quick notes:
# 1. Using TK because we can take advantage of the plumbing to generate a
#    temporary sandbox, resolve cookbook deps, load 'em, and then iterate
#    over them to enumerate all resources for which we'll generate
#    recommended tests.
# 2. Using TK also feels right as perhaps this ability to generate an
#    initial set of tests automatically would be a useful feature *within* TK.
# NOTE: I learned that ChefDK has Kitchen-like support for Policyfile:
# https://github.com/chef/chef-dk/blob/9199ddcb6d1504749cbe689347d6b895b0bd889b/lib/kitchen/provisioner/policyfile_zero.rb
#
# 20170615
#  We can create a ChefDK::Policyfile::Uploader object and push the policyfile:
#  https://github.com/chef/chef-dk/blob/9199ddcb6d1504749cbe689347d6b895b0bd889b/lib/chef-dk/policyfile/uploader.rb#L75-L77
#  We need to create a PolicyfileLock object:
#  https://github.com/chef/chef-dk/blob/9199ddcb6d1504749cbe689347d6b895b0bd889b/lib/chef-dk/policyfile_lock.rb
#  Use the uploader spec for guidance:
#  https://github.com/chef/chef-dk/blob/9199ddcb6d1504749cbe689347d6b895b0bd889b/spec/unit/policyfile/uploader_spec.rb
#  CAVEAT: We may need to update the Policyfile to reflect we're using a chef-zero server (i.e. not local files).

require 'awesome_print' # DEBUG
require 'chef'
require 'chef/cookbook_loader'
require 'chef/cookbook_uploader'
require 'chef_zero/server'
require 'chef-dk/command/push'
require 'chef-dk/command/export'
require 'kitchen'
require 'kitchen/driver/dummy'
require 'kitchen/provisioner/chef_zero'
require 'kitchen/transport/ssh'
require 'kitchen/verifier/dummy'

### EXPORT
require 'chef-dk/policyfile_services/export_repo'
require 'tmpdir' # Extends Dir.
### EXPORT

# TODO: Test for this existing and so something appropriate.
policyfile_lock_file = 'Policyfile.lock.json'

cookbook_dir = File.basename(Dir.pwd)
export_root = Dir.mktmpdir('ramsay-')
# We need the target dir named the same as the source dir so that `chef` commands
# work as happily programatically as they would via the command line.
# This is because the commands assume they're being run from within a cookbook
# directory.
export_path = File.join(export_root, cookbook_dir)
export_service = ChefDK::PolicyfileServices::ExportRepo.new(
  policyfile: policyfile_lock_file,
  export_dir: export_path
)

puts "Exporting #{cookbook_dir} to #{export_path}..."
export_service.run
# TODO: Update .chef/config.rb to include a chef_server_url value appropriate
# for chef-zero so we can load up the config from the file via
# Chef::Config.from_file("#{export_path}/.chef/config.rb").
puts "Export Complete!"
chef_config_file = "#{export_path}/.chef/config.rb"
puts "Updating #{chef_config_file} with some important bits..."
File.open(chef_config_file, 'a') do |f|
  f.puts 'chef_server_url "http://127.0.0.1:8889"'
end
Chef::Config.from_file("#{export_path}/.chef/config.rb")
ap Chef::Config

=begin
# TODO: Thinking we may want to hake TK get its config from a Ramsay-specific
# Kitchen config file (i.e. kitchen.ramsay.yml).
ramsay_driver = Kitchen::Driver::Dummy.new
ramsay_platform = Kitchen::Platform.new({name: 'ramsay'})
provisioner_options = {
  test_base_path: '/tmp/ramsay-test-base-path',
  kitchen_root: Dir.pwd
}
ramsay_provisioner = Kitchen::Provisioner::ChefZero.new(provisioner_options)
ramsay_suite = Kitchen::Suite.new({name: 'sweet'})
ramsay_transport = Kitchen::Transport::Ssh.new
ramsay_verifier = Kitchen::Verifier::Dummy.new


instance_options = {
  suite: ramsay_suite,
  platform: ramsay_platform,
  driver: ramsay_driver,
  provisioner: ramsay_provisioner,
  transport: ramsay_transport,
  verifier: ramsay_verifier,
  state_file: '.kitchen/ramsay.yml'
}

# The provisioner needs an instance object as it depends on its values (like name).
instance = Kitchen::Instance.new(instance_options)
#ramsay_provisioner.create_sandbox
#sandbox_path = ramsay_provisioner.sandbox_path
#puts "SANDBOX PATH: #{sandbox_path}" # DEBUG
puts # DEBUG
=end

# Run our own chef-zero instance and use the cookbooks in the sandbox to
# enumerate the resources.
server = ChefZero::Server.new(port: 8889)
#server.start_background

json_args = nil # nil if we want to use Policyfile
#json_args = {"run_list" => "recipe[system-base]"}
#client = Chef::Client.new(json_args, local_mode: true)
#Chef::Config['chef_server_url'] = 'http://127.0.0.1:8889'
#Chef::Config['client_key'] = "#{sandbox_path}/validation.pem"
#Chef::Config['node_name'] = 'ramsay-node'
#Chef::Config['cookbook_path'] = "#{sandbox_path}/cookbook_artifacts"
#Chef::Config['use_policyfile'] = true
#Chef::Config['policy_group'] = 'ramsay-group'   # BE CLEVER
#Chef::Config['policy_name'] = 'ramsay-policy'   # BE CLEVER

=begin
# BEGIN NON-POLICYFILE COOKBOOK UPLOAD APPROACH
# Instantiate a CookbookLoader and generate CookbookVersion objects for all
# cookbooks.
cl = Chef::CookbookLoader.new(Chef::Config.cookbook_path)
cookbooks = cl.load_cookbooks
#puts cl.cookbook_names # DEBUG
# Iterate over the loaded cookbooks and add the Chef::CookbookVersion objects
# to an array we can feed to Chef::CookbookUploader and push them all at once.
all_cookbooks = []
cookbooks.each do |cb_name, cb_version|
  all_cookbooks << cb_version
end
uploader = Chef::CookbookUploader.new(all_cookbooks)
uploader.upload_cookbooks
# NOTE: Since we're using Policyfile, we'll need to mimic `chef push` behavior
# to push the Policyfile.lock.json and all cookbooks to the server.
# The above code can still be expanded upon for users not using Policyfile.
# END NON-POLICYFILE COOKBOOK UPLOAD APPROACH
=end

=begin
# get node information, including node_name, required to get/build node info;
# test afterward with `client.node_name`
client.run_ohai
client.load_node # from the server
client.build_node
client.setup_run_context # /me crosses fingers
my_resources = {}
client.run_status.run_context.resource_collection.each do |resource|
  if my_resources.has_key?(resource.to_s)
    my_resources[resource.to_s] += 1
  else
    my_resources[resource.to_s] = 1
  end
  puts "\nRESOURCE: '#{resource.to_s}'"
  puts "NAME:     '#{resource.name}'"
  puts "TYPE:     '#{resource.class}'"
  puts "ACTION:   '#{resource.action.to_s}'"
  puts "FROM:     '#{resource.cookbook_name}::#{resource.recipe_name}'"
end
=end

#ramsay_provisioner.cleanup_sandbox # SOON

# TODO: Ensure we shut down chef-zero (i.e. via at_exit)

