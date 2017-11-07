require 'chef-umami/version'

module Umami
  module Options
    # Parse command line options. Returns hash of options.
    def parse_options
      options = {}
      # Default options
      options[:integration_tests] = true
      options[:policyfile] = 'Policyfile.rb'
      options[:test_root] = 'spec'
      options[:unit_tests] = true

      parser = OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help message') {
          puts opts
          exit
        }
        opts.on('-i', '--[no-]integration-tests', 'Write integration tests' \
                " (DEFAULT: #{options[:integration_tests]})") do |integration_tests|
          options[:integration_tests] = integration_tests
        end
        opts.on('-p', '--policyfile POLICYFILE_PATH', 'Specify the path to a policy' \
                " (DEFAULT: #{options[:policyfile]})") do |policyfile|
          options[:policyfile] = policyfile
        end
        opts.on('-r', '--recipes RECIPE1,RECIPE2', Array,
                "Specify one or more recipes for which we'll write tests" \
                ' (DEFAULT: All recipes)') do |recipes|
          options[:recipes] = recipes
        end
        opts.on('-t', '--test-root TEST_ROOT_PATH', "Specify the path into which we'll write tests" \
                " (DEFAULT: #{options[:test_root]})") do |test_root|
          options[:test_root] = test_root
        end
        opts.on('-u', '--[no-]unit-tests', 'Write unit tests' \
                " (DEFAULT: #{options[:unit_tests]})") do |unit_tests|
          options[:unit_tests] = unit_tests
        end
        opts.on('-v', '--version', 'Show version and exit') {
          puts "chef-umami v#{Umami::VERSION}"
          exit
        }
      end
      parser.parse!
      options
    end
  end
end
