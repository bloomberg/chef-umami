module Ramsay
  module Helper
    module OS
      require 'rbconfig'

      # Attempt to determine the appropriate platform to use when instantiating
      # a ChefSpec runner object.
      # Refer to https://github.com/chefspec/fauxhai/blob/master/PLATFORMS.md
      def os
        @os ||= (
          host_os = RbConfig::CONFIG['host_os']
          case host_os
          when /aix/
            # `oslevel` => '7.1.0.0'
            version = `oslevel`[0..2]
            {platform: 'aix', version: version}
          when /darwin|mac os/
            version = `sw_vers -productVersion`.chomp
            {platform: 'mac_os_x', version: version}
          when /linux/
            # Perform very basic tests to determine distribution.
            if File.exist?('/etc/centos-release')
              version = File.read('/etc/redhat-release').split[2]
              {platform: 'centos', version: version}
            elsif File.exist?('/etc/redhat-release') # True for CentOS too...
              version = File.read('/etc/redhat-release').split[6]
              {platform: 'redhat', version: version}
            else
              {platform: 'centos', version: '7.3.1611'} # Default to something reasonably sane.
            end
          when /solaris/
            version = `uname -r`.chomp # Release level (i.e. 5.11).
            {platform: 'solaris', version: version}
          when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
            # Refer to https://en.wikipedia.org/wiki/Ver_(command)
            win_version = `ver`.chomp.split("Version ")[1].gsub(/]/, '')
            case win_version
            when /^6.1.7/
              version = '2008R2' # Also Win 7
            when /^6.2/
              version = '2012' # Also Win 8
            when /^6.3/
              version = '2012R2' # Also Win 8.1
            when /^(6.4|10)/
              version = '10'
            end
            {platform: 'windows', version: version}
          else
            # Default to something reasonably sane.
            {platform: 'centos', version: '7.3.1611'}
          end
        )
      end

    end
  end
end
