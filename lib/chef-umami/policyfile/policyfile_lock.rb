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

require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile_lock'
require 'chef-dk/ui'

module Umami
  class Policyfile
    class PolicyfileLock
      attr_reader :policyfile
      def initialize(policyfile = nil)
        @policyfile      = policyfile
        @policyfile_lock = nil
        @storage_config  = storage_config
        @ui              = ui
      end

      def storage_config
        @storage_config ||= ChefDK::Policyfile::StorageConfig.new.use_policyfile(policyfile)
      end

      def ui
        @ui ||= ChefDK::UI.new
      end

      def policyfile_lock_path
        policyfile.gsub(/\.rb$/, '.lock.json')
      end

      def policyfile_lock_content
        IO.read(policyfile_lock_path)
      end

      def lock_data
        FFI_Yajl::Parser.new.parse(policyfile_lock_content)
      end

      def policyfile_lock
        @policyfile_lock ||= ChefDK::PolicyfileLock.new(
          storage_config,
          ui: ui
        ).build_from_lock_data(lock_data)
      end

      def name
        policyfile_lock.name
      end
    end
  end
end
