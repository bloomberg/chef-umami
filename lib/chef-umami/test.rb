#   Copyright 2017 Bloomberg, L.P.
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

module Umami
  class Test

    attr_reader :root_dir
    def initialize
      @root_dir = 'spec'
    end

    # All subclasses should implement the following methods.

    # #framework should return a string describing the framework it's
    # expected to write tests for.
    # Examples:
    #  "chefspec"
    #  "serverspec"
    #  "inspec"
    def framework
      raise NoMethodError, "#{self.class} needs to implement the ##{__method__} method! Refer to Umami::Test."
    end

    # #preamble should return a string (with newlines) that will appear at
    # the top of a test file.
    # Expects a string representing the recipe name, at least.
    # Example:
    # "# #{test_root}/#{recipe}_spec.rb\n" \
    # "\n" \
    # "require '#{framework}'\n" \
    # "\n" \
    # "describe '#{recipe}' do\n" \
    # "  let(:chef_run) { ChefSpec::ServerRunner.converge(described_recipe) }"
    def preamble(recipe = '')
      raise NoMethodError, "#{self.class} needs to implement the ##{__method__} method! Refer to Umami::Test."
    end

    # #write_test should write a single, discreet test for a given resource.
    # Return as a string with newlines.
    # Expects a Chef::Resource object.
    def write_test(resource = nil)
      raise NoMethodError, "#{self.class} needs to implement the ##{__method__} method! Refer to Umami::Test."
    end

    # Performs the necessary steps to generate one or more tests within a
    # test file.
    def generate
      raise NoMethodError, "#{self.class} needs to implement the ##{__method__} method! Refer to Umami::Test."
    end

  end
end
