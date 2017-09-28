#   Copyright 2017 Bloomberg Finance, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'chef-umami/test'
require 'chef-umami/helpers/os'
require 'chef-umami/helpers/filetools'

module Umami
  class Test
    class Unit < Umami::Test

      include Umami::Helper::OS
      include Umami::Helper::FileTools

      attr_reader :test_root
      attr_reader :tested_cookbook # This cookbook.
      def initialize
        super
        @test_root = File.join(self.root_dir, 'umami', 'unit', 'recipes')
        @tested_cookbook = File.basename(Dir.pwd)
      end

      def framework
        "chefspec"
      end

      def test_file(recipe = '')
        "#{test_root}/#{recipe}_spec.rb"
      end

      def spec_helper_path
        File.join(test_root, '..', 'spec_helper.rb')
      end

      def preamble(cookbook = '', recipe = '')
        "# #{test_file(recipe)} - Originally written by Umami!\n" \
        "\n" \
        "require_relative '../spec_helper'\n" \
        "\n" \
        "describe '#{cookbook}::#{recipe}' do\n" \
        "let(:chef_run) { ChefSpec::ServerRunner.new(platform: '#{os[:platform]}', version: '#{os[:version]}').converge(described_recipe) }"
      end

      def write_spec_helper
        content = ["require '#{framework}'"]
        content << "require '#{framework}/policyfile'"
        content << "at_exit { ChefSpec::Coverage.report! }\n"
        write_file(spec_helper_path, content.join("\n"))
      end

      def write_test(resource = nil)
        state_attrs = [] # Attribute hash to be used with #with()
        resource.state.each do |attr, value|
          next if value.nil? or (value.respond_to?(:empty) and value.empty?)
          if value.is_a? String
            value = value.gsub("'", "\\\\'") # Escape any single quotes in the value.
          end
          state_attrs << "#{attr}: '#{value}'"
        end
        action = ''
        if resource.action.is_a? Array
          action = resource.action.first
        else
          action = resource.action
        end
        resource_name = resource.name.gsub("'", "\\\\'") # Escape any single quotes in the resource name.
        test_output = ["\nit '#{action}s #{resource.declared_type} \"#{resource_name}\"' do"]
        if state_attrs.empty?
          test_output << "expect(chef_run).to #{action}_#{resource.declared_type}('#{resource_name}')"
        else
          test_output << "expect(chef_run).to #{action}_#{resource.declared_type}('#{resource_name}').with(#{state_attrs.join(', ')})"
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
        write_spec_helper
        test_files_written << spec_helper_path

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
