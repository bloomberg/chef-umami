require 'chef-ramsay/test'
require 'chef-ramsay/helpers/os'

module Ramsay
  class Test
    class Unit < Ramsay::Test

      include Ramsay::Helper::OS

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

      def preamble(cookbook = '', recipe = '')
        "# #{test_root}/#{recipe}_spec.rb\n" \
        "\n" \
        "require '#{framework}'\n" \
        "\n" \
        "describe '#{cookbook}::#{recipe}' do\n" \
        "  let(:chef_run) { ChefSpec::ServerRunner.new(platform: '#{os[:platform]}', version: '#{os[:version]}').converge(described_recipe) }"
      end

      def write_test(resource = nil)
        state_attrs = [] # Attribute hash to be used with #with()
        resource.state.each do |attr, value|
          next if value.nil? or value.empty?
          state_attrs << "#{attr}: '#{value}'"
        end
        test_output = ["\n  it '#{resource.action.first}s #{resource.declared_type} \"#{resource.name}\"' do"]
        if state_attrs.empty?
          test_output << "    expect(chef_run).to #{resource.action.first}_#{resource.declared_type}('#{resource.name}')"
        else
          test_output << "    expect(chef_run).to #{resource.action.first}_#{resource.declared_type}('#{resource.name}').with(#{state_attrs.join(', ')})"
        end
        test_output << "  end\n"
        test_output.join("\n")
      end

      def generate(recipe_resources = {})
        recipe_resources.each do |canonical_recipe, resources|
          (cookbook, recipe) = canonical_recipe.split('::')
          # Only write unit tests for the cookbook we're in.
          next unless cookbook == tested_cookbook
          puts preamble(cookbook, recipe)
          resources.each do |resource|
            puts write_test(resource)
          end
          puts "end" # TODO: Make #footer def (or similar)
        end
      end

    end
  end
end
