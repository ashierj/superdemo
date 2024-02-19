# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    class WorkloadIdentityFederation < Integration
      attribute :alert_events, default: false
      attribute :commit_events, default: false
      attribute :confidential_issues_events, default: false
      attribute :confidential_note_events, default: false
      attribute :issues_events, default: false
      attribute :job_events, default: false
      attribute :merge_requests_events, default: false
      attribute :note_events, default: false
      attribute :pipeline_events, default: false
      attribute :push_events, default: false
      attribute :tag_push_events, default: false
      attribute :wiki_page_events, default: false
      attribute :comment_on_event_enabled, default: false

      with_options if: :activated? do
        validates :workload_identity_federation_project_id, presence: true
        validates :workload_identity_federation_project_number, presence: true, numericality: { only_integer: true }
        validates :workload_identity_pool_id, presence: true
        validates :workload_identity_pool_provider_id, presence: true
      end

      field :workload_identity_federation_project_id,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Google Cloud project ID') },
        description: -> {
          s_('GoogleCloudPlatformService|Google Cloud project ID for the Workload Identity Federation.')
        }

      field :workload_identity_federation_project_number,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Google Cloud project number') },
        description: -> {
          s_('GoogleCloudPlatformService|Google Cloud project number for the Workload Identity Federation.')
        }

      field :workload_identity_pool_id,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Workload Identity Pool ID') },
        description: -> { s_('GoogleCloudPlatformService|ID of the Workload Identity Pool.') }

      field :workload_identity_pool_provider_id,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Workload Identity Pool provider ID') },
        description: -> { s_('GoogleCloudPlatformService|ID of the Workload Identity Pool provider.') }

      def self.title
        s_('GoogleCloudPlatformService|Google Cloud Identity and Access Management')
      end

      def self.description
        s_('GoogleCloudPlatformService|Connect Google Cloud Workload Identity Federation to GitLab.')
      end

      def self.to_param
        'google_cloud_platform_workload_identity_federation'
      end

      def self.supported_events
        []
      end

      # We will make the integration testable in https://gitlab.com/gitlab-org/gitlab/-/issues/439885
      def testable?
        false
      end

      def identity_provider_resource_name
        return unless parent.google_cloud_workload_identity_federation_enabled? && activated?

        "//#{identity_pool_resource_name}/providers/#{workload_identity_pool_provider_id}"
      end

      def identity_pool_resource_name
        return unless parent.google_cloud_workload_identity_federation_enabled? && activated?

        "iam.googleapis.com/projects/#{workload_identity_federation_project_number}/" \
          "locations/global/workloadIdentityPools/#{workload_identity_pool_id}"
      end
    end
  end
end
