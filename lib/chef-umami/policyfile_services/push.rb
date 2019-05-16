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

require 'chef-dk/policyfile_services/push'

module Umami
  class PolicyfileServices
    class Push < ChefDK::PolicyfileServices::Push
      def initialize(policyfile: nil, ui: nil, policy_group: nil, config: nil, root_dir: nil)
        super(policyfile: policyfile, ui: ui, policy_group: policy_group,
              config: config, root_dir: root_dir)
      end

      # Keep up with the times and force use of the newer API.
      def api_version
        '2'
      end

      # We'll override the #http_client method to ensure we set the appropriate
      # API version we expect to be used. Chef::Authenticator#request_version
      # will use this to set the appropriate header that Chef Server (Zero)
      # uses to determine how to generate cookbook manifests. Without this, we
      # see issues during the Umami::Client#compile phase where Chef cannot
      # locate recipes within a cookbook and `umami` fails miserably.
      # I spent a week debugging this when trying to update `umami` to support
      # newer Chef libraries. That, too, was miserable.
      def http_client
        @http_client ||= Chef::ServerAPI.new(config.chef_server_url,
                                             signing_key_filename: config.client_key,
                                             client_name: config.node_name,
                                             api_version: api_version)
      end
    end
  end
end
