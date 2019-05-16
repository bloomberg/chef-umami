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

module Umami
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
      def enforce_styling(path = 'spec/umami/')
        puts "Running Rubocop over '#{path}' to enforce styling..."
        r = RuboCop::CLI.new
        # Don't output to STDOUT.
        args = [
          '--only', 'Layout/IndentationWidth,Layout/IndentationConsistency',
          '--auto-correct',
          '--out', '/dev/null',
          path
        ]
        r.run(args)
      end
    end
  end
end
