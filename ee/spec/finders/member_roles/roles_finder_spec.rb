# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRoles::RolesFinder, feature_category: :system_access do
  let(:params) { { parent: group } }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:member_role_1) { create(:member_role, name: 'Tester', namespace: group) }
  let_it_be(:member_role_2) { create(:member_role, name: 'Manager', namespace: group) }
  let_it_be(:group_2_member_role) { create(:member_role) }
  let_it_be(:active_group_iterations_cadence) do
    create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations')
  end

  subject(:find_member_roles) { described_class.new(user, params).execute }

  context 'without permissions' do
    context 'when filtering by group' do
      it 'does not return any member roles for group' do
        expect(find_member_roles).to be_empty
      end
    end

    context 'when filtering by id' do
      let(:params) { { id: member_role_2.id } }

      it 'does not return any member roles for id' do
        expect(find_member_roles).to be_empty
      end
    end
  end

  context 'with permissions' do
    before_all do
      group.add_owner(user)
    end

    context 'without custom roles feature' do
      before do
        stub_licensed_features(custom_roles: false)
      end

      it 'does not return any member roles for group' do
        expect(find_member_roles).to be_empty
      end
    end

    context 'with custom roles feature' do
      before do
        stub_licensed_features(custom_roles: true)
      end

      context 'when filtering by group' do
        it 'returns all member roles of the group' do
          expect(find_member_roles).to contain_exactly(member_role_2, member_role_1)
        end
      end

      context 'when filtering by project' do
        let(:params) { { parent: project } }

        it 'returns all member roles of the project root ancestor' do
          expect(find_member_roles).to contain_exactly(member_role_2, member_role_1)
        end
      end

      context 'when filtering by id' do
        let(:params) { { id: member_role_2.id } }

        it 'returns member role found by id' do
          expect(find_member_roles).to contain_exactly(member_role_2)
        end
      end

      context 'when filtering by multiple ids' do
        let(:params) { { id: [member_role_1.id, member_role_2.id, group_2_member_role.id] } }

        it 'returns only member roles a user can read' do
          expect(find_member_roles).to contain_exactly(member_role_2, member_role_1)
        end
      end
    end
  end
end
