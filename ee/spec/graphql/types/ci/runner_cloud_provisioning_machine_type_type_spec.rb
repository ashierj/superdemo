# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunnerCloudProvisioningMachineType'], feature_category: :fleet_visibility do
  specify do
    expect(described_class.description).to eq('Machine type used for runner cloud provisioning.')
  end

  it 'includes all expected fields' do
    expected_fields = %w[zone name description]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
