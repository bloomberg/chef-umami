require 'chef-umami/version'
require 'choice'

module Umami
  module Options
    # Command line options.
    def parse_options
      Choice.options do
        header ''
        header "A taste you won't forget!"
        header ''
        header 'Options:'
        option :integration_tests do
          short '-i'
          long  '--integration-tests'
          desc  'Write integration tests'
          desc  'Default: true'
          default true
        end

        option :policyfile do
          short '-p'
          long  '--policyfile=POLICYFILE'
          desc  'Specify the path to a policy'
          desc  'Default: Policyfile.rb'
          default 'Policyfile.rb'
        end

        option :recipe do
          short '-r'
          long  '--recipe *RECIPES'
          desc  "Specify one or more recipes for which we'll write tests"
          desc 'Default: (All recipes)'
        end

        option :test_root do
          short '-t'
          long  '--test-root=TEST_ROOT'
          desc  "Specify the path into which we'll write tests"
          desc  'Default: spec/umami'
          default 'spec/umami'
        end

        option :unit_tests do
          short '-u'
          long  '--unit-tests'
          desc  'Write unit tests'
          desc  'Default: true'
          default true
        end

        option :version do
          short '-v'
          long  '--version'
          desc  'Show version and exit'
          action do
            puts "chef-umami v#{Umami::VERSION}"
            exit
          end
        end
        footer ''
      end
    end
  end
end
