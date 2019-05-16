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

require 'chef-umami/runner'

RSpec.describe Umami::Runner do
  it 'initiates a Umami::Runner object' do
    runner = Umami::Runner.new
    expect(runner).to be_an_instance_of(Umami::Runner)
    expect(runner.chef_zero_server).to be_an_instance_of(Umami::Server)
  end

  context 'with no options provided' do
    it 'sets proper defaults' do
      runner = Umami::Runner.new
      expect(runner.umami_config[:integration_tests]).to be true
      expect(runner.policyfile).to eq("Policyfile.rb")
      expect(runner.umami_config[:test_root]).to eq("spec")
      expect(runner.umami_config[:unit_tests]).to be true
    end
  end

  context 'with options provided' do
    it 'parses them properly' do
      my_argv = %w(--policyfile test_policy.rb)
      my_argv << '--no-integration-tests'
      my_argv << %w(--test-root dust_spec)
      my_argv << '--no-unit-tests'
      my_argv.flatten!
      stub_const("ARGV", my_argv)
      runner = Umami::Runner.new
      expect(runner.umami_config[:integration_tests]).to be false
      expect(runner.policyfile).to eq("test_policy.rb")
      expect(runner.umami_config[:test_root]).to eq("dust_spec")
      expect(runner.umami_config[:unit_tests]).to be false
    end
  end

  describe '.validate_lock_file!' do
    context 'when the policy lock file is missing' do
      it 'raises an Umami::InvalidPolicyfileLockFilename exception' do
        my_argv = %w(--policyfile definitely_does_not_exist.rb)
        stub_const("ARGV", my_argv)
        runner = Umami::Runner.new
        expect{runner.validate_lock_file!}.to raise_error(Umami::InvalidPolicyfileLockFilename)
      end
    end

    context 'when the policy lock file exists' do
      it 'does not raise an exception' do
        my_argv = %w(--policyfile definitely_does_not_exist.rb)
        allow(File).to receive(:exist?).with('definitely_does_not_exist.lock.json').and_return(true)
        stub_const("ARGV", my_argv)
        runner = Umami::Runner.new
        expect{runner.validate_lock_file!}.not_to raise_error
      end
    end
  end
end
