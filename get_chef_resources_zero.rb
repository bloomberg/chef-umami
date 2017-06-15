#!/opt/chef/embedded/bin/ruby

#
# get_chef_resource_zero.rb - Run Chef compile-time phase and generate a
# list of resources via chef-zero
#

require 'chef_zero/server'
require 'chef'
require 'chef/cookbook_loader'
require 'chef/cookbook_uploader'
require 'json'
server = ChefZero::Server.new(port: 8889)
server.start_background

#json_args = nil
json_args = {"run_list" => "recipe[system-base]"}
client = Chef::Client.new(json_args, local_mode: true)
Chef::Config['chef_server_url'] = 'http://127.0.0.1:8889'
Chef::Config['client_key'] = 'frantz-zero.pem'
Chef::Config['node_name'] = 'frantz-zero'
#Chef::Config['cookbook_path'] = '/home/rfrantz1/git/system-base'
Chef::Config['cookbook_path'] = '/home/rfrantz1/git'
Chef::Config['run_list'] = 'system-base'
#cookbook = 'system-base' # needs to be an actual cookbook object?
cl = Chef::CookbookLoader.new(Chef::Config.cookbook_path)
#puts cl.methods.sort - Object.methods
cl.load_cookbooks
# DAMN! Loading cookbooks with the current cookbook_path means
# all the subdirs get pulled in as cookbooks! Ain't right!
#
# attributes (Chef::CookbookVersion)
# files (Chef::CookbookVersion)
# libraries (Chef::CookbookVersion)
# recipes (Chef::CookbookVersion)
# test (Chef::CookbookVersion)
# templates (Chef::CookbookVersion)
#cl.cookbooks.each do |cb|
#  puts "#{cb.name} (#{cb.class})"
#end
puts cl.cookbook_names

cookbook = cl.load_cookbook('system-base')
uploader = Chef::CookbookUploader.new(cookbook, {cookbook_path: Chef::Config.cookbook_path})
uploader.upload_cookbooks # Fails because can't resolve 'apt' cookbook dependency
# We would need all the dependent cookbooks in our cookbook path...
#puts "\n\n#{Chef::Config.inspect}\n\n"
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

=begin
# We may have duplicate resources. Address this. Doesn't Chef ensure these are merged?
#puts "#{my_resources.sort_by {|key, value| value}.reverse}"

# TODOs
# If resource clas matches /Chef::Resource/ let’s generate some tests;
# call out the others for future attention
# Look out for resources without a name! (RESOURCE: '' == Chef::Resource::YumPackage)

client.run_status.run_context.resource_collection.each do |resource|
  #if resource.to_s == 'git_config[url.https://github.com/.insteadOf]'
  #if resource.to_s == 'cron[chef-client]'
  #if resource.to_s == 'template[/etc/profile.d/chruby.sh]'
  if resource.to_s == 'ark[terraform]' # Custom resource
    puts "\n#{resource.class}"
    puts "\n#{resource}"
    puts "#{resource.inspect}"
    puts "\nRESOURCE CLASS METHODS"
    puts "#{resource.class.methods.sort - Object.methods}"
    puts "\nPROPERTIES"
    #puts resource.class.properties.class
    #puts resource.class.properties.inspect
    resource.class.properties.each do |key, value|
      puts "\n\t[#{key}] => #{value}"
      puts "\t#{value.class}"
      #puts "\t#{value.inspect}"
      #puts "\tMETHODS: #{value.methods.sort - Object.methods}"
      #puts "\tHAS DEFAULT?: #{value.has_default?.to_s}"
      #puts "\tDEFAULT VALUE CLASS: #{value.default.class}"
      #puts "\tDEFAULT VALUE: #{value.default}"
      # Seems funny that to get the property value we need to pass in the resource
      # as an argument.
      ultimate_value = value.get(resource) # Gets value, default, value, or lazy-evaluated value.
      puts "\tULTIMATE VALUE: #{ultimate_value} (#{ultimate_value.class})"
      puts "\tWILL NOT WRITE TEST FOR '#{key}' PROPERTY AS IT IS NIL" if ultimate_value.nil?
    end
    #puts "\nSTATE PROPERTIES"
    #resource.class.state_properties.each {|property| puts "\t[#{property}]"}
  end
end
=end

server.stop
