# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::CreatorService, feature_category: :groups_and_projects do
  describe '.add_member' do
    let_it_be(:user) { create(:user) }

    context 'for free user limit considerations', :saas do
      let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

      before do
        stub_ee_application_setting(dashboard_limit: 1)
        stub_ee_application_setting(dashboard_limit_enabled: true)
        create(:group_member, source: group)
      end

      context 'when ignore_user_limits is not passed and uses default' do
        it 'fails to add the member' do
          member = described_class.add_member(group, user, :owner)

          expect(member).not_to be_persisted
          expect(group.users.reload).not_to include(user)
          expect(member.errors.full_messages).to include(/cannot be added since you've reached/)
        end
      end

      context 'when ignore_user_limits is passed as true' do
        it 'adds the member' do
          member = described_class.add_member(group, user, :owner, ignore_user_limits: true)

          expect(member).to be_persisted
        end
      end
    end

    context 'when a `member_role_id` is passed', feature_category: :permissions do
      let_it_be(:group) { create(:group) }
      let_it_be(:member_role) { create(:member_role, namespace: group) }

      subject(:member) { described_class.add_member(group, user, :owner, member_role_id: member_role.id) }

      context 'when custom roles are enabled' do
        before do
          stub_licensed_features(custom_roles: true)
        end

        it 'saves the `member_role`' do
          expect(member.member_role).to eq(member_role)
        end
      end

      context 'when custom roles are not enabled' do
        it 'does not save the `member_role`' do
          expect(member.member_role).to eq(nil)
        end
      end
    end
  end
end
