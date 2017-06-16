#!/opt/chef/embedded/bin/ruby

# Export a cookbook, it's Policyfile, and dependent cookbooks to a
# temporary location.
#
# Assumes it's being run *from* a cookbook directory.

require 'chef-dk'
require 'chef-dk/policyfile_services/export_repo'
require 'tmpdir' # Extends Dir.

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
puts "Done!"
