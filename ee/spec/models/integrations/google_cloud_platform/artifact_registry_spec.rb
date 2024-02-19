# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GoogleCloudPlatform::ArtifactRegistry, feature_category: :package_registry do
  subject(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration) }

  describe 'attributes' do
    describe 'default values' do
      it { is_expected.not_to be_alert_events }
      it { is_expected.not_to be_commit_events }
      it { is_expected.not_to be_confidential_issues_events }
      it { is_expected.not_to be_confidential_note_events }
      it { is_expected.not_to be_issues_events }
      it { is_expected.not_to be_job_events }
      it { is_expected.not_to be_merge_requests_events }
      it { is_expected.not_to be_note_events }
      it { is_expected.not_to be_pipeline_events }
      it { is_expected.not_to be_push_events }
      it { is_expected.not_to be_tag_push_events }
      it { is_expected.not_to be_wiki_page_events }
      it { is_expected.not_to be_comment_on_event_enabled }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:workload_identity_pool_project_number) }
    it { is_expected.to validate_presence_of(:workload_identity_pool_id) }
    it { is_expected.to validate_presence_of(:workload_identity_pool_provider_id) }
    it { is_expected.to validate_presence_of(:artifact_registry_project_id) }
    it { is_expected.to validate_presence_of(:artifact_registry_location) }
    it { is_expected.to validate_presence_of(:artifact_registry_repositories) }

    context 'when inactive integration' do
      subject(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration, :inactive) }

      it { is_expected.not_to validate_presence_of(:workload_identity_pool_project_number) }
      it { is_expected.not_to validate_presence_of(:workload_identity_pool_id) }
      it { is_expected.not_to validate_presence_of(:workload_identity_pool_provider_id) }
      it { is_expected.not_to validate_presence_of(:artifact_registry_project_id) }
      it { is_expected.not_to validate_presence_of(:artifact_registry_location) }
      it { is_expected.not_to validate_presence_of(:artifact_registry_repositories) }
    end
  end

  describe '.title' do
    subject { described_class.title }

    it { is_expected.to eq(s_('GoogleCloudPlatformService|Google Cloud Artifact Registry')) }
  end

  describe '.description' do
    subject { described_class.description }

    it do
      is_expected.to eq(s_('GoogleCloudPlatformService|Connect Google Cloud Artifact Registry to GitLab.'))
    end
  end

  describe '.to_param' do
    subject { described_class.to_param }

    it { is_expected.to eq('google_cloud_platform_artifact_registry') }
  end

  describe '#artifact_registry_repository' do
    subject { integration.artifact_registry_repository }

    it { is_expected.to eq(integration.artifact_registry_repositories) }
  end

  describe '.supported_events' do
    subject { described_class.supported_events }

    it { is_expected.to eq([]) }
  end

  describe '#identity_provider_resource_name' do
    let(:expected) do
      "//iam.googleapis.com/projects/#{integration.workload_identity_pool_project_number}/" \
        "locations/global/workloadIdentityPools/#{integration.workload_identity_pool_id}/" \
        "providers/#{integration.workload_identity_pool_provider_id}"
    end

    subject { integration.identity_provider_resource_name }

    it { is_expected.to eq(expected) }
  end

  describe '#testable?' do
    subject { integration.testable? }

    it { is_expected.to be_falsey }
  end

  describe '#ci_variables' do
    subject { integration.ci_variables }

    it { is_expected.to eq([]) }

    context 'with saas only enabled' do
      before do
        stub_saas_features(google_cloud_support: true)
      end

      context 'when integration is inactive' do
        let(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration, :inactive) }

        it { is_expected.to eq([]) }
      end

      context 'when integration is active' do
        it do
          is_expected.to contain_exactly(
            { key: 'GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID',
              value: integration.artifact_registry_project_id },
            { key: 'GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME',
              value: integration.artifact_registry_repository },
            { key: 'GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION',
              value: integration.artifact_registry_location }
          )
        end
      end
    end
  end

  describe '#sections' do
    subject { integration.sections }

    it { is_expected.to eq([{ type: 'google_cloud_artifact_registry' }]) }
  end
end
