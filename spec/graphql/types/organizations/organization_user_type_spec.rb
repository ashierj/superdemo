# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationUser'], feature_category: :cell do
  let(:expected_fields) { %w[badges id user] }

  specify { expect(described_class.graphql_name).to eq('OrganizationUser') }
  specify { expect(described_class).to require_graphql_authorizations(:read_organization_user) }
  specify { expect(described_class).to have_graphql_fields(*expected_fields) }
end
