require 'chef-dk/authenticated_http'
require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile/uploader'
require 'chef-dk/policyfile_lock'
require 'chef-dk/ui'

module Ramsay
  class Policyfile
    class Uploader

      attr_reader :http_client
      attr_reader :policyfile_lock
      attr_reader :policyfile_lock_file
      attr_reader :policyfile_uploader
      attr_reader :storage_config
      attr_reader :ui
		  def initialize(policyfile_lock_file = nil)
        @http_client = http_client
        @policyfile_lock_file = policyfile_lock_file
        @policyfile_lock = policyfile_lock
        @policyfile_uploader = policyfile_uploader
        @storage_config = storage_config
        @ui = ui
		  end

      def storage_config
        @storage_config ||= ChefDK::Policyfile::StorageConfig.new.use_policyfile(policyfile_lock_file)
      end

      def ui
        @ui ||= ChefDK::UI.new
      end

      def policyfile_lock_content
        IO.read(policyfile_lock_file)
      end

      def lock_data
        FFI_Yajl::Parser.new.parse(policyfile_lock_content)
      end

      def policyfile_lock
        @policyfile_lock ||= ChefDK::PolicyfileLock.new(
          storage_config,
          ui: ui
        ).build_from_lock_data(lock_data)
      end

      def http_client
        @http_client ||= ChefDK::AuthenticatedHTTP.new(Chef::Config['chef_server_url'])
      end

      def policy_group
        Chef::Config['policy_group']
      end

      def policy_document_native_api
        true
      end

      def policyfile_uploader
        @policyfile_uploader ||= ChefDK::Policyfile::Uploader.new(
          policyfile_lock,
          policy_group,
          ui: ui,
          http_client: http_client,
          policy_document_native_api: policy_document_native_api
        )
      end

      # Push the policy, including all dependent cookbooks.
      def upload
        policyfile_uploader.upload
      end

    end
  end
end
