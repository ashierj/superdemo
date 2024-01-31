# frozen_string_literal: true

require 'spec_helper'

# Creation is necessary due to relations and the need to check in the presenter
#
# rubocop:disable RSpec/FactoryBot/AvoidCreate
RSpec.describe MemberPresenter, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:root_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: root_group) }
  let_it_be(:member_root, reload: true) { create(:group_member, :reporter, group: root_group, user: user) }
  let_it_be(:member_subgroup, reload: true) { create(:group_member, :reporter, group: subgroup, user: user) }

  let(:current_user) { user }

  subject(:presenter) { described_class.new(member_root, current_user: current_user) }

  describe '#human_access' do
    context 'when user has static role' do
      it 'returns human name for access level' do
        access_levels = {
          "Guest" => Gitlab::Access::GUEST,
          "Reporter" => Gitlab::Access::REPORTER,
          "Developer" => Gitlab::Access::DEVELOPER,
          "Maintainer" => Gitlab::Access::MAINTAINER,
          "Owner" => Gitlab::Access::OWNER
        }

        access_levels.each do |human_name, access_level|
          member_root.access_level = access_level
          expect(presenter.human_access).to eq human_name
        end
      end

      context 'when user has a custom role' do
        it 'returns custom roles' do
          member_role = create(:member_role, :guest, namespace: root_group)
          member_root.member_role = member_role
          member_root.access_level = Gitlab::Access::GUEST

          expect(presenter.human_access).to eq('Custom')
        end
      end
    end
  end

  describe '#valid_member_roles' do
    let_it_be(:member_role_guest) { create(:member_role, :guest, name: 'guest plus', namespace: root_group) }
    let_it_be(:member_role_reporter) { create(:member_role, :reporter, name: 'reporter plus', namespace: root_group) }

    let_it_be(:member_role_instance) do
      create(:member_role, :guest, :instance, name: 'guest plus (instance-level)')
    end

    before do
      stub_licensed_features(custom_roles: true)
      stub_saas_features(group_custom_roles: false)
    end

    context 'when the user has permissions to manage group roles' do
      before_all do
        root_group.add_owner(user)
      end

      it 'returns only roles with higher base_access_level than user highest membership in the hierarchy' do
        expect(described_class.new(member_subgroup, current_user: user).valid_member_roles).to match_array(
          [
            {
              base_access_level: Gitlab::Access::REPORTER,
              member_role_id: member_role_reporter.id,
              name: 'reporter plus'
            }
          ]
        )
      end

      it 'returns all roles for the root group and the instance' do
        expect(presenter.valid_member_roles).to match_array(
          [
            {
              base_access_level: Gitlab::Access::REPORTER,
              member_role_id: member_role_reporter.id,
              name: 'reporter plus'
            },
            {
              base_access_level: Gitlab::Access::GUEST,
              member_role_id: member_role_guest.id,
              name: 'guest plus'
            },
            {
              base_access_level: Gitlab::Access::GUEST,
              member_role_id: member_role_instance.id,
              name: 'guest plus (instance-level)'
            }
          ]
        )
      end
    end
  end

  describe '#custom_permissions' do
    context 'when user has static role' do
      it 'returns an empty array' do
        expect(presenter.custom_permissions).to be_empty
      end
    end

    context 'when user has custom role' do
      it 'returns its abilities' do
        member_role = build_stubbed(
          :member_role, namespace: root_group, read_vulnerability: true, admin_merge_request: true
        )
        member_root.member_role = member_role

        expect(presenter.custom_permissions).to match_array(
          [{ key: :read_vulnerability, name: 'Read vulnerability' },
            { key: :admin_merge_request, name: 'Admin merge request' }]
        )
      end
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
