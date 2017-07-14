module Ramsay
  module Helper
    module ServerSpec

      # ServerSpec supports the following backends:
      #  :exec - Local execution. Good for Test Kitchen
      #  :ssh  - Remote execution via SSH.
      def backend
        :exec.inspect
      end

      def desciption(resource)
        "describe #{resource.declared_type}('#{resource.name}') do"
      end

      # All test methods should follow the naming convention 'test_<resource type>'
      #  1. The methods should build up an array of lines defining the test.
      #  1. The first element should be the result of a call to
      #  #description(resource) except in cases where it is not appropriate
      #  (i.e. testing a directory resource requires #  defining a file test).
      #  2. The method should should return a string joined by newlines.
      #
      #def test_wutang(resource)
      #  test = [desciption(resource)]
      #  test.join("\n")
      #end

      def test_cron(resource)
        test = [desciption(resource)]
        cron_entry = "#{resource.minute} "  \
                     "#{resource.hour} "    \
                     "#{resource.day} "     \
                     "#{resource.month} "   \
                     "#{resource.weekday} " \
                     "#{resource.command}"
        test << "it { should have_entry('#{cron_entry}').with_user('#{resource.user}') }"
        test << "end"
        test.join("\n")
      end

      def test_directory(resource)
        # directory tests are really file tests.
        test = ["describe file('#{resource.name}') do"]
        test << "it { should be_directory }"
        if !resource.group.nil? && !resource.group.empty?
          test << "it { should be_grouped_into '#{resource.group}' }"
        end
        if !resource.owner.nil? && !resource.owner.empty?
          test << "it { should be_owned_by '#{resource.owner}' }"
        end
        if !resource.mode.nil? && !resource.mode.empty?
          test << "it { should be_mode '#{resource.mode}' }"
        end
        test << "end"
        test.join("\n")
      end
      alias_method :test_remote_directory, :test_directory

      def test_file(resource)
        test = ["describe file('#{resource.name}') do"]
        test << "it { should be_file }"
        if !resource.group.nil? && !resource.group.empty?
          test << "it { should be_grouped_into '#{resource.group}' }"
        end
        if !resource.owner.nil? && !resource.owner.empty?
          test << "it { should be_owned_by '#{resource.owner}' }"
        end
        if !resource.mode.nil? && !resource.mode.empty?
          test << "it { should be_mode '#{resource.mode}' }"
        end
        test << "end"
        test.join("\n")
      end
      alias_method :test_cookbook_file, :test_file
      alias_method :test_remote_file, :test_file
      alias_method :test_template, :test_file

      def test_group(resource)
        test = [desciption(resource)]
        test << "it { should exist }"
        test << "end"
        test.join("\n")
      end

      def test_package(resource)
        test = [desciption(resource)]
        if !resource.version.nil? && !resource.version.empty?
          test << "it { should be_installed.with_version('#{resource.version}') }"
        else
          test << "it { should be_installed }"
        end
        test << "end"
        test.join("\n")
      end

      def test_user(resource)
        test = [desciption(resource)]
        test << "it { should exist }"
        if !resource.gid.nil? && !resource.gid.empty?
          test << "it { should belong_to_primary_group '#{resource.gid}' }"
        end
        if !resource.home.nil? && !resource.home.empty?
          test << "it { should have_home_directory '#{resource.home}' }"
        end
        test << "end"
        test.join("\n")
      end

    end
  end
end
