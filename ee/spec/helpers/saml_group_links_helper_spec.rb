# frozen_string_literal: true

require "spec_helper"

RSpec.describe SamlGroupLinksHelper, feature_category: :system_access do
  let_it_be(:group) { create_default(:group) }
  let_it_be(:member_role) { create_default(:member_role, namespace: group) }
  let_it_be(:saml_group_link) { create_default(:saml_group_link, group: group, member_role: member_role) }

  describe '#saml_group_link_role_selector_data', feature_category: :permissions do
    let(:expected_standard_role_data) { { standard_roles: group.access_level_roles } }
    let(:expected_custom_role_data) do
      { custom_roles: [{ member_role_id: member_role.id,
                         name: member_role.name,
                         base_access_level: member_role.base_access_level }] }
    end

    subject(:data) { helper.saml_group_link_role_selector_data(group) }

    before do
      stub_licensed_features(custom_roles: true)
    end

    it 'returns a hash with the expected standard and custom role data' do
      expect(data).to eq(expected_standard_role_data.merge(expected_custom_role_data))
    end

    context 'when custom roles are not enabled' do
      before do
        stub_licensed_features(custom_roles: false)
      end

      it 'returns a hash with the expected standard role data' do
        expect(data).to eq(expected_standard_role_data)
      end
    end

    context 'when the `custom_roles_for_saml_group_links` feature flag is disabled' do
      before do
        stub_feature_flags(custom_roles_for_saml_group_links: false)
      end

      it 'returns a hash with the expected standard role data' do
        expect(data).to eq(expected_standard_role_data)
      end
    end
  end

  describe '#saml_group_link_role_name' do
    subject { helper.saml_group_link_role_name(saml_group_link) }

    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'when a member role is present' do
      it { is_expected.to eq(member_role.name) }
    end

    context 'when a member role is not present' do
      let_it_be(:saml_group_link) { create_default(:saml_group_link, group: group, member_role: nil) }

      it { is_expected.to eq(::Gitlab::Access.human_access(saml_group_link.access_level)) }
    end

    context 'when custom roles are disabled' do
      before do
        stub_licensed_features(custom_roles: false)
      end

      it { is_expected.to eq(::Gitlab::Access.human_access(saml_group_link.access_level)) }
    end

    context 'when the `custom_roles_for_saml_group_links` feature flag is disabled' do
      before do
        stub_feature_flags(custom_roles_for_saml_group_links: false)
      end

      it { is_expected.to eq(::Gitlab::Access.human_access(saml_group_link.access_level)) }
    end
  end
end
