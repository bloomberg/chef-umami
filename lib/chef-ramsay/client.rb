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

    # Get node information, including node_name, required to get/build node info;
    # test afterward with `client.node_name`
    def prep
      client.run_ohai
      client.load_node # from the server
      client.build_node
      client.setup_run_context
    end

    # TODO: This can only be called after #prep completes successfully.
    # Add some check to determine if the client is actually prepped.
    def resource_collection
      client.run_status.run_context.resource_collection
    end

  end
end
