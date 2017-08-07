require 'chef-ramsay/test'
require 'chef-ramsay/helpers/serverspec'
require 'chef-ramsay/helpers/filetools'

module Ramsay
  class Test
    class Integration < Ramsay::Test

      include Ramsay::Helper::ServerSpec
      include Ramsay::Helper::FileTools

      attr_reader :test_root
      attr_reader :tested_cookbook # This cookbook.
      def initialize
        super
        @test_root = File.join(self.root_dir, 'ramsay', 'integration')
        @tested_cookbook = File.basename(Dir.pwd)
      end

      def framework
        "serverspec"
      end

      def test_file(cookbook = '', recipe = '')
        "#{test_root}/#{cookbook}_#{recipe}_spec.rb"
      end

      def preamble(cookbook = '', recipe = '')
        "# #{test_file(cookbook, recipe)}\n" \
        "\n" \
        "require '#{framework}'\n" \
        "set :backend, #{backend}"
      end

      # Call on the apprpriate method from the Ramsay::Helper::ServerSpec
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
          test_file_name = test_file(cookbook, recipe)
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
