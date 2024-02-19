# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::CreateService, '#execute', feature_category: :groups_and_projects do
  subject { described_class.new(group, shared_with_group, user, opts) }

  let_it_be(:shared_with_group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  let(:role) { Gitlab::Access::DEVELOPER }
  let(:opts) do
    {
      shared_group_access: role,
      expires_at: nil
    }
  end

  describe 'audit event creation' do
    let(:audit_context) do
      {
        name: 'group_share_with_group_link_created',
        stream_only: false,
        author: user,
        scope: group,
        target: shared_with_group,
        message: "Invited #{shared_with_group.name} to the group #{group.name}"
      }
    end

    before do
      shared_with_group.add_guest(user)
      group.add_owner(user)
    end

    it 'sends an audit event' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).once

      subject.execute
    end
  end

  context 'when current user has admin_group_member custom permission' do
    let_it_be(:member, reload: true) { create(:group_member, group: group, user: user) }
    let_it_be(:member_role, reload: true) do
      create(:member_role, namespace: group, admin_group_member: true)
    end

    shared_examples 'adding members using custom permission' do
      subject(:share_group) { described_class.new(group, shared_with_group, user, opts).execute }

      before do
        shared_with_group.add_guest(user)

        # it is more efficient to change the base_access_level than to create a new member_role
        member_role.base_access_level = current_role
        member_role.save!(validate: false)

        member.update!(access_level: current_role, member_role: member_role)
      end

      context 'when custom_roles feature is enabled' do
        before do
          stub_licensed_features(custom_roles: true)
        end

        context 'when adding group link with the same access role as current user' do
          let(:role) { current_role }

          it 'adds a group link' do
            expect { share_group }.to change { group.shared_with_group_links.count }.by(1)
          end
        end

        context 'when adding group link with higher role than current user' do
          let(:role) { higher_role }

          it 'fails to add the group link' do
            expect { share_group }.not_to change { group.shared_with_group_links.count }
          end
        end
      end

      context 'when custom_roles feature is disabled' do
        before do
          stub_licensed_features(custom_roles: false)
        end

        context 'when adding members with the same access role as current user' do
          let(:role) { current_role }

          it 'fails to add the group link' do
            expect { share_group }.not_to change { group.shared_with_group_links.count }
          end
        end
      end
    end

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
end
