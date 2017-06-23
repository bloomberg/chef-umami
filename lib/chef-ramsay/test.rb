module Ramsay
  class Test

    attr_reader :root_dir
    def initialize
      @root_dir = 'spec'
    end

    # All subclasses should implement #framework. It should return a string
    # describing the framework it's expected to write tests for.
    # Examples:
    #  "chefspec"
    #  "serverspec"
    #  "inspec"
    def framework
      raise NoMethodError, "#{self.class} needs to implement the ##{__method__} method! Refer to Ramsay::Test."
    end

  end
end
