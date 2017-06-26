require 'chef-ramsay/test'
require 'chef-ramsay/helpers/serverspec'

module Ramsay
  class Test
    class Integration < Ramsay::Test

      include Ramsay::Helper::ServerSpec

      attr_reader :test_root
      attr_reader :tested_cookbook # This cookbook.
      def initialize
        super
        @test_root = File.join(self.root_dir, 'integration', 'ramsay')
        @tested_cookbook = File.basename(Dir.pwd)
      end

      def framework
        "serverspec"
      end

      def preamble(cookbook = '', recipe = '')
        "# #{test_root}/#{cookbook}/#{recipe}_spec.rb\n" \
        "\n" \
        "require '#{framework}'\n" \
        "\n" \
      end

      # Call on the apprpriate method from the Ramsay::Helper::ServerSpec
      # module to generate our test.
      def write_test(resource = nil)
        "\n" + send("test_#{resource.declared_type}", resource)
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
        end
      end

    end
  end
end
