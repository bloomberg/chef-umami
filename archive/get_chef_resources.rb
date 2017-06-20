#!/opt/chef/embedded/bin/ruby

#
# get_chef_resource.rb - Run Chef compile-time phase and generate a list of resources
#
# This is preliminary code to build on an idea to auto-generate integration
# tests for Chef runs.

require 'chef'
client = Chef::Client.new(nil, Chef::Config.from_file('/etc/chef/client.rb')) # TODO: Allow for an option to define alternate config so we can customize things like 'policy_name'
Chef::Config['config_file'] = '/etc/chef/client.rb' # required when we set up run context as an ohai plugin complains
#chef_org = 'bloomberg'
chef_org = 'chef'
Chef::Config['chef_server_url'] = "https://chef.ny.cas.inf.bloomberg.com/organizations/#{chef_org}"
#Chef::Config['policy_name'] = 'baseline'
#Chef::Config['policy_group'] = 's0'
client.run_ohai # get node information, including node_name, required to get/build node info; test afterward with `client.node_name`
client.load_node # from the server; can/should we fake this when we don't have a real node in the org?
client.build_node
client.setup_run_context # /me crosses fingers
my_resources = {}
cookbook_to_test = 'system-base'
resources_to_test = []
client.run_status.run_context.resource_collection.each do |resource|
#  puts "\nRESOURCE: '#{resource.to_s}'"
#  puts "NAME:     '#{resource.name}'"
#  puts "TYPE:     '#{resource.class}'"
#  puts "ACTION:   '#{resource.action.to_s}'"
#  puts "FROM:     '#{resource.cookbook_name}::#{resource.recipe_name}'"
  if resource.cookbook_name == cookbook_to_test
    resources_to_test << resource
    if my_resources.has_key?(resource.to_s)
      my_resources[resource.to_s] += 1
    else
      my_resources[resource.to_s] = 1
    end
  end
end

# TODOs
# If resource clas matches /Chef::Resource/ let’s generate some tests; call out the others for future attention
#  Look out for resources without a name! (RESOURCE: '' == Chef::Resource::YumPackage)

puts "Inspecting a single resource..."
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
=begin
      METHODS: [:call, :coerce, :declared_in, :default, :derive, :desired_state?, :emit_dsl, :explicitly_accepts_nil?, :get, :get_value, :has_default?, :identity?, :instance_variable_name, :is_set?, :name_property?, :options, :required?, :reset, :reset_value, :sensitive?, :set, :set_value, :validate, :validation_options, :value_is_set?]
=end
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

puts "\n\Resources for '#{cookbook_to_test}'"
puts "Resource count: #{resources_to_test.length}"
resources_to_test.each do |resource|
 puts "#{resource.to_s} [#{resource.class}] from recipe '#{resource.recipe_name}'"
end

puts
# We may have duplicate resources. Address this. Doesn't Chef ensure these are merged?
#puts "#{my_resources.sort_by {|key, value| value}.reverse}"
my_resources.each do |resource, count|
  puts "DUPE RESOURCE (#{resource}) SEEN #{count} TIMES" if count > 1
end

