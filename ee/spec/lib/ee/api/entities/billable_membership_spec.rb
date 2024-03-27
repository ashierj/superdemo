# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::BillableMembership, feature_category: :seat_cost_management do
  let_it_be(:membership) { create(:group_member, :developer) }
  let(:entity) do
    {
      id: membership.id,
      source_id: membership.group.id,
      source_full_name: membership.group.full_name,
      source_members_url: Gitlab::Routing.url_helpers.group_group_members_url(membership.group),
      created_at: membership.created_at,
      expires_at: membership.expires_at,
      access_level: {
        string_value: 'Developer',
        integer_value: 30
      }
    }
  end

  subject(:entity_representation) { described_class.new(membership).as_json }

  it 'exposes the expected attributes' do
    expect(entity_representation).to eq entity
  end
end
