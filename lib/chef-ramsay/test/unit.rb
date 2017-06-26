require 'chef-ramsay/test'

module Ramsay
  class Test
    class Unit < Ramsay::Test

      attr_reader :test_root
      attr_reader :tested_cookbook # This cookbook.
      def initialize
        super
        @test_root = File.join(self.root_dir, 'unit', 'ramsay', 'recipes')
        @tested_cookbook = File.basename(Dir.pwd)
      end

      def framework
        "chefspec"
      end

      def preamble(recipe = '')
    	  puts "# #{test_root}/#{recipe}_spec.rb"
    	  puts
    	  puts "require '#{framework}'"
    	  puts
    	  puts "describe '#{recipe}' do"
    	  puts "  let(:chef_run) { ChefSpec::ServerRunner.converge(described_recipe) }"
      end

			def write_test(resource = nil)
        puts 
        puts "  it '#{resource.action.first}s #{resource.declared_type} \"#{resource.name}\"' do"
        puts "    expect(chef_run).to #{resource.action.first}_#{resource.declared_type}('#{resource.name}')"
        state_attrs = resource.state.keys.map {|attr| ":#{attr}"}.join(', ')
        puts "    expect(resource).to have_state_attrs(#{state_attrs})"
        puts "  end"
			end

      def generate(recipe_resources = {})
      	recipe_resources.each do |canonical_recipe, resources|
      	  (cookbook, recipe) = canonical_recipe.split('::')
          # Only write unit tests for the cookbook we're in.
					next unless cookbook == tested_cookbook
          preamble(recipe)
        	resources.each do |resource|
						write_test(resource)
        	end
        	puts "end" # TODO: Make #footer def (or similar)
				end
      end

    end
  end
end
