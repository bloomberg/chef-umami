require 'chef_zero/server'

module Ramsay
  class Server
    def initialize
      @server = server
    end

    def server
      @server ||= ChefZero::Server.new(port: 8889)
    end

    def start
      server.start_background
    end

    def stop
      server.stop
    end

  end
end
