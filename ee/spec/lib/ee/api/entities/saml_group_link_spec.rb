# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::API::Entities::SamlGroupLink, feature_category: :system_access do
  describe 'exposes expected fields' do
    let_it_be(:member_role) { create(:member_role) }
    let_it_be(:saml_group_link) { create(:saml_group_link, member_role: member_role) }

    subject(:entity) { described_class.new(saml_group_link).as_json }

    context 'when custom roles are enabled' do
      before do
        stub_licensed_features(custom_roles: true)
      end

      it 'exposes the attributes' do
        expect(entity[:name]).to eq saml_group_link.saml_group_name
        expect(entity[:access_level]).to eq saml_group_link.access_level
        expect(entity[:member_role_id]).to eq saml_group_link.member_role_id
      end
    end

    context 'when custom roles are not enabled' do
      it 'does not expose `member_role_id`' do
        expect(entity.keys).not_to include(:member_role_id)
      end
    end

    context 'when the `custom_roles_for_saml_group_links` feature flag is not enabled' do
      before do
        stub_feature_flags(custom_roles_for_saml_group_links: false)
      end

      it 'does not expose `member_role_id`' do
        expect(entity.keys).not_to include(:member_role_id)
      end
    end
  end
end
