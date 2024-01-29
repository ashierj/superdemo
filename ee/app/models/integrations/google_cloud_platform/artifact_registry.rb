# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    class ArtifactRegistry < Integration
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
        validates :workload_identity_pool_project_number, presence: true
        validates :workload_identity_pool_id, presence: true
        validates :workload_identity_pool_provider_id, presence: true
        validates :artifact_registry_project_id, presence: true
        validates :artifact_registry_location, presence: true
        validates :artifact_registry_repositories, presence: true
      end

      field :artifact_registry_project_id,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Google Cloud project ID') },
        description: -> { s_('GoogleCloudPlatformService|ID of the Google Cloud project.') }

      field :workload_identity_pool_project_number,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Workload Identity Pool project number') },
        description: -> { s_('GoogleCloudPlatformService|Project number of the Workload Identity Pool.') }

      field :workload_identity_pool_id,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Workload Identity Pool ID') },
        description: -> { s_('GoogleCloudPlatformService|ID of the Workload Identity Pool.') }

      field :workload_identity_pool_provider_id,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Workload Identity Pool provider ID') },
        description: -> { s_('GoogleCloudPlatformService|ID of the Workload Identity Pool provider.') }

      field :artifact_registry_location,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Location of Artifact Registry repository') },
        description: -> { s_('GoogleCloudPlatformService|Location of Artifact Registry repository.') }

      field :artifact_registry_repositories,
        required: true,
        title: -> { s_('GoogleCloudPlatformService|Repository of Artifact Registry') },
        help: -> { s_('GoogleCloudPlatformService|Repository of Artifact Registry.') },
        description: -> { s_('GoogleCloudPlatformService|Repository of Artifact Registry.') }

      alias_method :artifact_registry_repository, :artifact_registry_repositories

      def self.title
        s_('GoogleCloudPlatformService|Google Cloud Artifact Registry')
      end

      def self.description
        s_('GoogleCloudPlatformService|Connect Google Cloud Artifact Registry to GitLab.')
      end

      def self.to_param
        'google_cloud_platform_artifact_registry'
      end

      def self.supported_events
        []
      end

      def wlif
        "//iam.googleapis.com/projects/#{workload_identity_pool_project_number}/" \
          "locations/global/workloadIdentityPools/#{workload_identity_pool_id}/" \
          "providers/#{workload_identity_pool_provider_id}"
      end

      # We will make the integration testable in https://gitlab.com/gitlab-org/gitlab/-/issues/438560
      def testable?
        false
      end
    end
  end
end
