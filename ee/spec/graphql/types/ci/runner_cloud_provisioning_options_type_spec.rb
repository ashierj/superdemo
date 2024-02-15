# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunnerCloudProvisioningOptions'], feature_category: :fleet_visibility do
  it 'returns all possible types' do
    expect(described_class.possible_types).to include(
      ::Types::Ci::RunnerGoogleCloudProvisioningOptionsType
    )
  end

  describe '#resolve_type' do
    using RSpec::Parameterized::TableSyntax

    where(:provider, :expected_type) do
      :google_cloud | ::Types::Ci::RunnerGoogleCloudProvisioningOptionsType
    end

    subject(:resolved_type) do
      described_class.resolve_type({ project: nil, provider: provider, cloud_project_id: 'some_project_id' }, {})
    end

    with_them do
      specify { expect(resolved_type).to eq(expected_type) }
    end

    context 'when provider is unknown' do
      let(:provider) { :unknown }

      it 'raises an error' do
        expect { resolved_type }.to raise_error(Types::Ci::RunnerCloudProvisioningOptionsType::UnexpectedProviderType)
      end
    end
  end
end
