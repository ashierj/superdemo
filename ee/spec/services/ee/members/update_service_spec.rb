# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::UpdateService, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:member_user) { create(:user) }
  let(:permission) { :update }
  let(:expiration) { 2.days.from_now }
  let(:original_access_level) { Gitlab::Access::DEVELOPER }
  let(:access_level) { Gitlab::Access::MAINTAINER }
  let(:member) { source.members_and_requesters.find_by!(user_id: member_user.id) }
  let(:params) do
    { access_level: access_level, expires_at: expiration }
  end

  let(:audit_role_expiration_from) { nil }
  let(:audit_role_from) { "Default role: #{Gitlab::Access.human_access(original_access_level)}" }
  let(:audit_role_to) { "Default role: #{Gitlab::Access.human_access(access_level)}" }
  let(:audit_role_details) do
    {
      change: 'access_level',
      from: audit_role_from,
      to: audit_role_to,
      expiry_from: audit_role_expiration_from,
      expiry_to: expiration.to_date,
      as: audit_role_to,
      member_id: member.id
    }
  end

  shared_examples_for 'logs an audit event' do
    specify do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(name: "member_updated", additional_details: audit_role_details)
      ).and_call_original

      expect do
        described_class.new(current_user, params).execute(member, permission: permission)
      end.to change { AuditEvent.count }.by(1)
    end
  end

  shared_examples_for 'does not log an audit event' do
    specify do
      expect do
        described_class.new(current_user, params).execute(member, permission: permission)
      end.not_to change { AuditEvent.count }
    end
  end

  context 'when current user can update the given member' do
    before_all do
      project.add_developer(member_user)
      group.add_developer(member_user)

      project.add_maintainer(current_user)
      group.add_owner(current_user)
    end

    it_behaves_like 'logs an audit event' do
      let(:source) { project }
    end

    it_behaves_like 'logs an audit event' do
      let(:source) { group }
    end

    context 'when the update is a noOp' do
      subject(:service) { described_class.new(current_user, params) }

      before do
        service.execute(member, permission: permission)
      end

      it_behaves_like 'does not log an audit event' do
        let(:source) { group }
      end

      it_behaves_like 'does not log an audit event' do
        let(:source) { project }
      end

      context 'when access_level remains the same and expires_at changes' do
        let(:expiration_from) { 24.days.from_now }
        let(:original_access_level) { Gitlab::Access::MAINTAINER }

        let(:audit_role_expiration_from) { expiration_from.to_date }

        before do
          described_class.new(
            current_user,
            params.merge(expires_at: expiration_from)
          ).execute(member, permission: permission)
        end

        it_behaves_like 'logs an audit event' do
          let(:source) { group }
        end
      end

      context 'when expires_at remains the same and access_level changes' do
        before do
          described_class.new(
            current_user,
            params.merge(access_level: original_access_level)
          ).execute(member, permission: permission)
        end

        let(:original_access_level) { Gitlab::Access::OWNER }
        let(:audit_role_expiration_from) { expiration.to_date }

        it_behaves_like 'logs an audit event' do
          let(:source) { group }
        end
      end
    end

    context 'when updating a member role of a member' do
      let_it_be(:member, reload: true) { create(:group_member, :guest, group: group) }
      let_it_be(:member_role_guest) { create(:member_role, :guest, namespace: group) }
      let_it_be(:member_role_reporter) { create(:member_role, :reporter, namespace: group) }

      let(:params) { { expires_at: expiration, member_role_id: target_member_role&.id } }
      let(:original_access_level) { Gitlab::Access::GUEST }

      subject(:update_member) { described_class.new(current_user, params).execute(member) }

      before do
        stub_licensed_features(custom_roles: true)
      end

      shared_examples 'correct member role assignement' do
        it 'returns success' do
          expect(update_member[:status]).to eq(:success)
        end

        it 'assigns the role correctly' do
          expect { update_member }.to change { member.reload.member_role }
            .from(initial_member_role).to(target_member_role)
        end
      end

      context 'when the member does not have any member role assigned yet' do
        let(:initial_member_role) { nil }
        let(:target_member_role) { member_role_guest }

        let(:audit_role_to) { "Custom role: #{member_role_guest.name}" }
        let(:audit_role_as) { "Custom role: #{member_role_guest.name}" }

        it_behaves_like 'correct member role assignement'

        it_behaves_like 'logs an audit event' do
          let(:source) { group }
        end
      end

      context 'when the user does not have access to the member role' do
        let(:initial_member_role) { nil }
        let(:target_member_role) { create(:member_role, :guest, namespace: create(:group)) }

        it 'returns error' do
          expect(update_member[:status]).to eq(:error)
          expect(update_member[:message]).to eq(
            'Member namespace must be in same hierarchy as custom role\'s namespace'
          )
        end
      end

      context 'when assigning the user to an instance-level member role' do
        let(:initial_member_role) { nil }
        let(:target_member_role) { create(:member_role, :guest, :instance) }

        it_behaves_like 'correct member role assignement'
      end

      context 'when the member has a member role assigned' do
        before do
          member.update!(member_role: initial_member_role)
        end

        let(:initial_member_role) { member_role_guest }
        let(:target_member_role) { member_role_reporter }

        let(:audit_role_from) { "Custom role: #{member_role_guest.name}" }
        let(:audit_role_to) { "Custom role: #{member_role_reporter.name}" }
        let(:audit_role_as) { "Custom role: #{member_role_reporter.name}" }

        it_behaves_like 'correct member role assignement'

        it_behaves_like 'logs an audit event' do
          let(:source) { group }
        end

        it 'changes the access level of the member accordingly' do
          update_member

          expect(member.reload.access_level).to eq(target_member_role.base_access_level)
        end

        context 'when invalid access_level is provided' do
          let(:params) { { member_role_id: target_member_role&.id, access_level: GroupMember::DEVELOPER } }

          it 'returns error' do
            expect(update_member[:status]).to eq(:error)
          end
        end
      end

      context 'when downgrading to static role' do
        before do
          member.update!(member_role: initial_member_role)
        end

        let(:initial_member_role) { member_role_guest }
        let(:target_member_role) { nil }

        it_behaves_like 'correct member role assignement'
      end
    end
  end
end
