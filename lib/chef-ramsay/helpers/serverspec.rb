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
