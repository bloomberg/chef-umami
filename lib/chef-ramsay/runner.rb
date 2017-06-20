module Ramsay
  class Runner
    def initialize(msg = '')
      @msg = msg
    end

    def msg
      @msg
    end

    def run
      puts "MESSAGE: #{msg}"
    end
  end
end
