# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunnerCloudProvisioningRegion'], feature_category: :fleet_visibility do
  specify do
    expect(described_class.description).to eq('Region used for runner cloud provisioning.')
  end

  it 'includes all expected fields' do
    expected_fields = %w[name description]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
