require 'chef-ramsay/test'
require 'chef-ramsay/helpers/os'
require 'chef-ramsay/helpers/filetools'

module Ramsay
  class Test
    class Unit < Ramsay::Test

      include Ramsay::Helper::OS
      include Ramsay::Helper::FileTools

      attr_reader :test_root
      attr_reader :tested_cookbook # This cookbook.
      def initialize
        super
        @test_root = File.join(self.root_dir, 'ramsay', 'unit', 'recipes')
        @tested_cookbook = File.basename(Dir.pwd)
      end

      def framework
        "chefspec"
      end

      def test_file(recipe = '')
        "#{test_root}/#{recipe}_spec.rb"
      end

      def preamble(cookbook = '', recipe = '')
        "# #{test_file(recipe)}\n" \
        "\n" \
        "require '#{framework}'\n" \
        "require '#{framework}/policyfile'\n" \
        "\n" \
        "describe '#{cookbook}::#{recipe}' do\n" \
        "let(:chef_run) { ChefSpec::ServerRunner.new(platform: '#{os[:platform]}', version: '#{os[:version]}').converge(described_recipe) }"
      end

      def write_test(resource = nil)
        state_attrs = [] # Attribute hash to be used with #with()
        resource.state.each do |attr, value|
          next if value.nil? or (value.respond_to?(:empty) and value.empty?)
          state_attrs << "#{attr}: '#{value}'"
        end
        action = ''
        if resource.action.is_a? Array
          action = resource.action.first
        else
          action = resource.action
        end
        test_output = ["\nit '#{action}s #{resource.declared_type} \"#{resource.name}\"' do"]
        if state_attrs.empty?
          test_output << "expect(chef_run).to #{action}_#{resource.declared_type}('#{resource.name}')"
        else
          test_output << "expect(chef_run).to #{action}_#{resource.declared_type}('#{resource.name}').with(#{state_attrs.join(', ')})"
        end
        test_output << "end\n"
        test_output.join("\n")
      end

      def generate(recipe_resources = {})
        test_files_written = []
        recipe_resources.each do |canonical_recipe, resources|
          (cookbook, recipe) = canonical_recipe.split('::')
          # Only write unit tests for the cookbook we're in.
          next unless cookbook == tested_cookbook
          content = [preamble(cookbook, recipe)]
          resources.each do |resource|
            content << write_test(resource)
          end
          content << "end"
          test_file_name = test_file(recipe)
          test_file_content = content.join("\n") + "\n"
          write_file(test_file_name, test_file_content)
          test_files_written << test_file_name
        end

        enforce_styling(test_root)

        unless test_files_written.empty?
          puts "Wrote the following unit test files:"
          test_files_written.each do |f|
            puts "\t#{f}"
          end
        end

      end

    end
  end
end
