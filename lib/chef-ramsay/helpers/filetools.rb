module Ramsay
  module Helper
    module FileTools

    require 'fileutils'
    require 'rubocop'

    def write_file(path = nil, content = '')
      parent_dir = File.dirname(path)
      FileUtils.mkdir_p(parent_dir) unless ::File.exist?(parent_dir)
      f = File.open(path, 'w') # Write with prejudice.
      f.write(content)
      f.close
    end

    # Call Rubocop to ensure proper indentation and thus legibility.
    def enforce_styling(path = 'spec/ramsay/')
      puts "Running Rubocop over '#{path}' to enforce styling..."
      r = RuboCop::CLI.new
      # Don't output to STDOUT.
      args = [
        '--only', 'Style/IndentationWidth,Style/IndentationConsistency',
        '--auto-correct',
        '--out', '/dev/null',
        path
      ]
      r.run(args)
    end

    end
  end
end
