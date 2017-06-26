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
