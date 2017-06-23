require 'chef-ramsay/test'

module Ramsay
  class Test
    class Unit < Ramsay::Test

      attr_reader :test_root
      attr_reader :recipe_dir
      def initialize
        super
        @test_root = File.join(self.root_dir, 'unit', 'ramsay')
        @recipe_dir = File.join(@test_root, 'recipes')
      end

      def framework
        "chefspec"
      end

    end
  end
end
