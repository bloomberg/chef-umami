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
require 'chef-umami/helpers/inspec'
require 'chef-umami/helpers/filetools'

module Umami
  class Test
    class Integration < Umami::Test

      include Umami::Helper::InSpec
      include Umami::Helper::FileTools

      attr_reader :test_root
      def initialize
        super
        @test_root = File.join(self.root_dir, 'umami', 'integration')
      end

      # InSpec doesn't need a require statement to use its tests.
      # We define #framework here for completeness.
      def framework
        "inspec"
      end

      def test_file_path(cookbook = '', recipe = '')
        "#{test_root}/#{cookbook}_#{recipe}_spec.rb"
      end

      def preamble(cookbook = '', recipe = '')
        "# #{test_file_path(cookbook, recipe)} - Originally written by Umami!"
      end

      # Call on the apprpriate method from the Umami::Helper::InSpec
      # module to generate our test.
      def write_test(resource = nil)
        if resource.action.is_a? Array
          return if resource.action.include?(:delete)
        end
        return if resource.action == :delete
        "\n" + send("test_#{resource.declared_type}", resource)
      end

      # If the test framework's helper module doesn't provide support for a
      # given test-related method, return a friendly message.
      # Raise NoMethodError for any other failed calls.
      def method_missing(m, *args, &block)
        case m
          when /^test_/
            "# #{m} is not currently defined. Stay tuned for updates."
          else
            raise NoMethodError
        end
      end

      def generate(recipe_resources = {})
        test_files_written = []
        recipe_resources.each do |canonical_recipe, resources|
          (cookbook, recipe) = canonical_recipe.split('::')
          content = [preamble(cookbook, recipe)]
          resources.each do |resource|
            content << write_test(resource)
          end
          test_file_name = test_file_path(cookbook, recipe)
          test_file_content = content.join("\n") + "\n"
          write_file(test_file_name, test_file_content)
          test_files_written << test_file_name
        end

        enforce_styling(test_root)

        unless test_files_written.empty?
          puts "Wrote the following integration tests:"
          test_files_written.each do |f|
            puts "\t#{f}"
          end
        end

      end

    end
  end
end
