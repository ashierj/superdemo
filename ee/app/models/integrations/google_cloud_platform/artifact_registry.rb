# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    class ArtifactRegistry < Integration
      SECTION_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY = 'google_cloud_artifact_registry'

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
        validates :artifact_registry_project_id, presence: true
        validates :artifact_registry_location, presence: true
        validates :artifact_registry_repositories, presence: true
      end

      field :artifact_registry_project_id,
        required: true,
        section: SECTION_TYPE_CONNECTION,
        title: -> { s_('GoogleCloudPlatformService|Google Cloud project ID') },
        label_description: -> { s_('GoogleCloudPlatformService|Project with the Artifact Registry repository.') },
        help: -> { artifact_registry_project_id_help }

      field :artifact_registry_repositories,
        required: true,
        section: SECTION_TYPE_CONNECTION,
        title: -> { s_('GoogleCloudPlatformService|Repository name') },
        help: -> { s_('GoogleCloudPlatformService|Repository must be Docker format and Standard mode.') }

      field :artifact_registry_location,
        required: true,
        section: SECTION_TYPE_CONNECTION,
        title: -> { s_('GoogleCloudPlatformService|Repository location') }

      alias_method :artifact_registry_repository, :artifact_registry_repositories

      def self.title
        s_('GoogleCloudPlatformService|Google Artifact Registry')
      end

      def self.description
        s_('GoogleCloudPlatformService|Manage your artifacts in Google Artifact Registry.')
      end

      def self.to_param
        'google_cloud_platform_artifact_registry'
      end

      def sections
        [
          {
            type: SECTION_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY
          }
        ]
      end

      def self.supported_events
        []
      end

      # TODO This will need an update when the integration handles multi repositories
      # artifact_registry_repository will not be available anymore.
      def repository_full_name
        "projects/#{artifact_registry_project_id}/" \
          "locations/#{artifact_registry_location}/" \
          "repositories/#{artifact_registry_repository}"
      end

      def required_integration_activated?
        !!project.google_cloud_platform_workload_identity_federation_integration&.activated?
      end

      def required_integration_class
        ::Integrations::GoogleCloudPlatform::WorkloadIdentityFederation
      end

      # We will make the integration testable in https://gitlab.com/gitlab-org/gitlab/-/issues/438560
      def testable?
        false
      end

      def ci_variables
        return [] unless project.gcp_artifact_registry_enabled? && activated?

        [
          { key: 'GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID', value: artifact_registry_project_id },
          { key: 'GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME', value: artifact_registry_repository },
          { key: 'GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION', value: artifact_registry_location }
        ]
      end

      def self.artifact_registry_project_id_help
        url = 'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects'

        format(
          s_('GoogleCloudPlatformService|To improve security, use a dedicated project for resources, separate from ' \
             'CI/CD and identity management projects. %{link_start}Where’s my project ID? %{icon}%{link_end}'),
          link_start: format('<a target="_blank" rel="noopener noreferrer" href="%{url}">', url: url).html_safe, # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
          link_end: '</a>'.html_safe,
          icon: ApplicationController.helpers.sprite_icon('external-link').html_safe # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
        )
      end
    end
  end
end
