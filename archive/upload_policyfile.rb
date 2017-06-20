#!/opt/chef/embedded/bin/ruby

# Ideas/code blatantly stolen from
# https://github.com/chef/chef-dk/blob/9199ddcb6d1504749cbe689347d6b895b0bd889b/lib/chef-dk/policyfile_services/update_attributes.rb
# -and-
# https://github.com/chef/chef-dk/blob/9199ddcb6d1504749cbe689347d6b895b0bd889b/spec/unit/policyfile/uploader_spec.rb

require 'chef-dk'
require 'chef-dk/authenticated_http'
require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile_lock'
require 'chef-dk/policyfile/uploader'
require 'chef-dk/ui'

policyfile_lock_file = 'Policyfile.lock.json'
storage_config = ChefDK::Policyfile::StorageConfig.new.use_policyfile(policyfile_lock_file)
ui = ChefDK::UI.new
#policyfile_lock_content = IO.read(policyfile_lock_expanded_path)
policyfile_lock_content = IO.read(policyfile_lock_file)

lock_data = FFI_Yajl::Parser.new.parse(policyfile_lock_content)
policyfile_lock = ChefDK::PolicyfileLock.new(
  storage_config,
  ui: ui
).build_from_lock_data(lock_data)

chef_server_url = 'http://localhost:8889'
http_client = ChefDK::AuthenticatedHTTP.new(chef_server_url)

policy_group = 'ramsay-group'
policy_document_native_api = true
policyfile_uploader = ChefDK::Policyfile::Uploader.new(
  policyfile_lock,
  policy_group,
  ui: ui,
  http_client: http_client,
  policy_document_native_api: policy_document_native_api
)
# We need to create a directory named the same as the policy so that we can
# execute a policy upload the same as one would from the command line, within
# a cookbook directory where a Policyfile is expected to reside.
# Otherwise we see an exception like so:
#
# The cookbook at path source `.' is expected to be named `system-base', but is now named `chef-ramsay'
# (full path: /home/rfrantz1/git/chef-ramsay) (ChefDK::MalformedCookbook)
#
# Funny enough, we need to load the Policyfile so we can get the name, then
# copy/link it into the temp/fake directory so that the #upload_policy method
# doesn't vomit.
pwd = Dir.pwd
fake_cookbook_dir = File.join(pwd, policyfile_uploader.policy_name)
# TODO: Add better error handling here such as carefully cleaning up old
# directories, testing for existing files, etc. We always want a clean set
# to run with.
Dir.rmdir(fake_cookbook_dir) if Dir.exist?(fake_cookbook_dir)
Dir.mkdir(fake_cookbook_dir)
Dir.chdir(fake_cookbook_dir)

# If we don't create this symlink, then we see an exception like so:
#
# The directory /home/rfrantz1/git/chef-ramsay/system-base does not contain a
# cookbook (Chef::Exceptions::CookbookNotFoundInRepo)
#
# This is because #upload_policy passes policyfile_lock.to_lock as an argument
# to the HTTP PUT request. #to_lock eventually ends up calling #validate!
# in cookbook_locks.rb where cookbook validation is attempted. Odd that we can
# still trick it out this way without actually having cookbooks present!
File.symlink(File.join('..', policyfile_lock_file), File.join(fake_cookbook_dir, policyfile_lock_file))
p "I'm in #{Dir.pwd}"
policyfile_uploader.upload_policy
