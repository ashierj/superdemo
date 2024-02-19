# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GoogleCloudPlatform::WorkloadIdentityFederation, feature_category: :integrations do
  subject(:integration) { build_stubbed(:google_cloud_platform_workload_identity_federation_integration) }

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
    it { is_expected.to validate_presence_of(:workload_identity_federation_project_id) }
    it { is_expected.to validate_presence_of(:workload_identity_federation_project_number) }
    it { is_expected.to validate_presence_of(:workload_identity_pool_id) }
    it { is_expected.to validate_presence_of(:workload_identity_pool_provider_id) }
    it { is_expected.to validate_numericality_of(:workload_identity_federation_project_number).only_integer }

    context 'when inactive integration' do
      subject(:integration) do
        build_stubbed(:google_cloud_platform_workload_identity_federation_integration, :inactive)
      end

      it { is_expected.not_to validate_presence_of(:workload_identity_federation_project_id) }
      it { is_expected.not_to validate_presence_of(:workload_identity_federation_project_number) }
      it { is_expected.not_to validate_presence_of(:workload_identity_pool_id) }
      it { is_expected.not_to validate_presence_of(:workload_identity_pool_provider_id) }
    end
  end

  describe '.title' do
    subject { described_class.title }

    it { is_expected.to eq(s_('GoogleCloudPlatformService|Google Cloud Identity and Access Management')) }
  end

  describe '.description' do
    subject { described_class.description }

    it do
      is_expected.to eq(s_('GoogleCloudPlatformService|Connect Google Cloud Workload Identity Federation to GitLab.'))
    end
  end

  describe '.to_param' do
    subject { described_class.to_param }

    it { is_expected.to eq('google_cloud_platform_workload_identity_federation') }
  end

  describe '.supported_events' do
    subject { described_class.supported_events }

    it { is_expected.to eq([]) }
  end

  describe '#testable?' do
    subject { integration.testable? }

    it { is_expected.to be_falsey }
  end

  describe '#identity_provider_resource_name' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group) }
    let_it_be(:project_integration) { create(:google_cloud_platform_workload_identity_federation_integration) }
    let_it_be(:group_integration) do
      create(:google_cloud_platform_workload_identity_federation_integration, project: nil, group: group)
    end

    let(:expected_resource_name) do
      "//iam.googleapis.com/projects/#{integration.workload_identity_federation_project_number}/" \
        "locations/global/workloadIdentityPools/#{integration.workload_identity_pool_id}/" \
        "providers/#{integration.workload_identity_pool_provider_id}"
    end

    subject { integration.identity_provider_resource_name }

    where(:integration, :active) do
      ref(:project_integration) | true
      ref(:project_integration) | false
      ref(:group_integration) | true
      ref(:group_integration) | false
    end

    with_them do
      before do
        integration.update!(active: active) unless active
      end

      it { is_expected.to be_nil }

      context 'when feature is available' do
        before do
          stub_saas_features(google_cloud_support: true)
        end

        if params[:active]
          it { is_expected.to eq(expected_resource_name) }
        else
          it { is_expected.to be_nil }
        end
      end

      context 'when google_cloud_workload_identity_federation FF is disabled' do
        before do
          stub_feature_flags(google_cloud_workload_identity_federation: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#identity_pool_resource_name' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group) }
    let_it_be(:project_integration) { create(:google_cloud_platform_workload_identity_federation_integration) }
    let_it_be(:group_integration) do
      create(:google_cloud_platform_workload_identity_federation_integration, project: nil, group: group)
    end

    let(:resource_name) do
      "iam.googleapis.com/projects/#{integration.workload_identity_federation_project_number}/" \
        "locations/global/workloadIdentityPools/#{integration.workload_identity_pool_id}"
    end

    subject { integration.identity_pool_resource_name }

    where(:integration, :active, :expected_resource_name) do
      ref(:project_integration) | true | ref(:resource_name)
      ref(:project_integration) | false | nil
      ref(:group_integration) | true | ref(:resource_name)
      ref(:group_integration) | false | nil
    end

    with_them do
      before do
        integration.update!(active: active) unless active
      end

      it { is_expected.to be_nil }

      context 'when feature is available' do
        before do
          stub_saas_features(google_cloud_support: true)
        end

        it { is_expected.to eq(expected_resource_name) }
      end

      context 'when google_cloud_workload_identity_federation FF is disabled' do
        before do
          stub_feature_flags(google_cloud_workload_identity_federation: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
