# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::CreatorService, feature_category: :groups_and_projects do
  describe '.add_member' do
    context 'for free user limit considerations', :saas do
      let_it_be(:user) { create(:user) }
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

      context 'when current user has admin_group_member custom permission' do
        let_it_be(:current_user) { create(:user) }
        let_it_be(:root_ancestor, reload: true) { create(:group) }
        let_it_be(:subgroup) { create(:group, parent: root_ancestor) }
        let_it_be(:member, reload: true) { create(:group_member, group: root_ancestor, user: current_user) }
        let_it_be(:member_role, reload: true) do
          create(:member_role, namespace: root_ancestor, admin_group_member: true)
        end

        let(:params) { { member_role_id: member_role.id, current_user: current_user } }

        shared_examples 'adding members using custom permission' do
          subject(:add_member) do
            described_class.add_member(group, user, role, **params)
          end

          before do
            member_role.update!(base_access_level: current_role)
            member.update!(access_level: current_role, member_role: member_role)
          end

          context 'when custom_roles feature is enabled' do
            before do
              stub_licensed_features(custom_roles: true)
            end

            context 'when adding members with the same access role as current user' do
              let(:role) { current_role }

              it 'adds members' do
                expect { add_member }.to change { group.members.count }.by(1)
              end
            end

            context 'when adding members with higher role than current user' do
              let(:role) { higher_role }

              it 'fails to add the member' do
                member = add_member

                expect(member).not_to be_persisted
                expect(group.users.reload).not_to include(user)
                expect(member.errors.full_messages)
                  .to include(/the member access level can't be higher than the current user's one/)
              end
            end
          end

          context 'when custom_roles feature is disabled' do
            before do
              stub_licensed_features(custom_roles: false)
            end

            context 'when adding members with the same access role as current user' do
              let(:role) { current_role }

              it 'does not add members' do
                expect { add_member }.not_to change { group.members.count }
              end
            end
          end
        end

        shared_examples 'adding members using custom permission to a group' do
          context 'for guest member role' do
            let(:current_role) { Gitlab::Access::GUEST }
            let(:higher_role) { Gitlab::Access::REPORTER }

            it_behaves_like 'adding members using custom permission'
          end

          context 'for reporter member role' do
            let(:current_role) { Gitlab::Access::REPORTER }
            let(:higher_role) { Gitlab::Access::DEVELOPER }

            it_behaves_like 'adding members using custom permission'
          end

          context 'for developer member role' do
            let(:current_role) { Gitlab::Access::DEVELOPER }
            let(:higher_role) { Gitlab::Access::MAINTAINER }

            it_behaves_like 'adding members using custom permission'
          end

          context 'for maintainer member role' do
            let(:current_role) { Gitlab::Access::MAINTAINER }
            let(:higher_role) { Gitlab::Access::OWNER }

            it_behaves_like 'adding members using custom permission'
          end
        end

        context 'when adding a member to the root group' do
          let(:group) { root_ancestor }

          it_behaves_like 'adding members using custom permission to a group'
        end

        context 'when adding a member to the subgroup' do
          let(:group) { subgroup }

          it_behaves_like 'adding members using custom permission to a group'
        end
      end
    end
  end
end
