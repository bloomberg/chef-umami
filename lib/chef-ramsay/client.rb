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

require 'chef'

module Ramsay
  class Client

    attr_reader :client
    def initialize
      @client = client
    end

    def client
      @client ||= Chef::Client.new
    end

    # Perform the steps required prior to compiling resources, including
    # running Ohai and building up the node object.
    def prep
      client.run_ohai
      client.load_node # from the server
      client.build_node
    end

    # Execute the compile phase of a Chef client run.
    def compile
      prep
      client.setup_run_context
    end

    # TODO: This can only be called after #prep completes successfully.
    # Add some check to determine if the client is actually prepped.
    def resource_collection
      client.run_status.run_context.resource_collection
    end

  end
end
