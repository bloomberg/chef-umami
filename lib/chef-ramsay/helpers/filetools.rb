module Ramsay
  module Helper
    module FileTools

    require 'fileutils'

    def write_file(path = nil, content = '')
      parent_dir = File.dirname(path)
      FileUtils.mkdir_p(parent_dir) unless ::File.exist?(parent_dir)
      f = File.open(path, 'w') # Write with prejudice.
      f.write(content)
      f.close
    end

    end
  end
end
