# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GoogleCloudPlatform::ArtifactRegistry, feature_category: :package_registry do
  let_it_be_with_reload(:project) { create(:project) }

  it_behaves_like Integrations::HasAvatar

  subject(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration, project: project) }

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
    it { is_expected.to validate_presence_of(:artifact_registry_project_id) }
    it { is_expected.to validate_presence_of(:artifact_registry_location) }
    it { is_expected.to validate_presence_of(:artifact_registry_repositories) }

    context 'when inactive integration' do
      subject(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration, :inactive) }

      it { is_expected.not_to validate_presence_of(:artifact_registry_project_id) }
      it { is_expected.not_to validate_presence_of(:artifact_registry_location) }
      it { is_expected.not_to validate_presence_of(:artifact_registry_repositories) }
    end
  end

  describe '.title' do
    subject { described_class.title }

    it { is_expected.to eq(s_('GoogleCloudPlatformService|Google Artifact Registry')) }
  end

  describe '.description' do
    subject { described_class.description }

    it do
      is_expected.to eq(s_('GoogleCloudPlatformService|Manage your artifacts in Google Artifact Registry.'))
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

  describe '#repository_full_name' do
    let(:expected) do
      "projects/#{integration.artifact_registry_project_id}/" \
        "locations/#{integration.artifact_registry_location}/" \
        "repositories/#{integration.artifact_registry_repository}"
    end

    subject { integration.repository_full_name }

    it { is_expected.to eq(expected) }
  end

  describe '#required_integration_activated?' do
    subject { integration.required_integration_activated? }

    it { is_expected.to be_falsey }

    context 'with the required integration' do
      let_it_be_with_refind(:wlif_integration) do
        create(:google_cloud_platform_workload_identity_federation_integration, project: project)
      end

      it { is_expected.to be_truthy }

      context 'when it is disabled' do
        before do
          wlif_integration.update_column(:active, false)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#required_integration_class' do
    subject { integration.required_integration_class }

    it { is_expected.to eq(::Integrations::GoogleCloudPlatform::WorkloadIdentityFederation) }
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
