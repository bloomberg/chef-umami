module Ramsay
  module Logger

    # Print messages.
    # TODO: Flesh this out so it supports different levels (i.e. info, warn).
    def log(msg = '', level = nil)
      puts msg
    end
  end
end
