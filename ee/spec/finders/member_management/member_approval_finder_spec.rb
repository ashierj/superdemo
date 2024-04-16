# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberManagement::MemberApprovalFinder, feature_category: :seat_cost_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let(:source) { group }

  subject(:finder) { described_class.new(current_user: user, params: {}, source: source) }

  describe '#initialize' do
    shared_examples 'invalid source arg' do
      it 'raises an ArgumentError' do
        expect do
          finder
        end.to raise_error(ArgumentError, 'Invalid source. Source should be either Group or Project.')
      end
    end

    context 'when source is nil' do
      let(:source) { nil }

      it_behaves_like "invalid source arg"
    end

    context 'when source is neither Project or Group' do
      let(:source) { create(:user_namespace) }

      it_behaves_like "invalid source arg"
    end
  end

  describe '#execute' do
    shared_examples 'when feature and settings are enabled' do
      let!(:pending_approval) { create(:member_approval, type, member_namespace: member_namespace) }

      let!(:rejected_approval) { create(:member_approval, type, member_namespace: member_namespace, status: 2) }

      context 'when user has admin access' do
        before do
          source.add_owner(user)
        end

        it 'returns pending member approvals for the source' do
          expect(finder.execute).to contain_exactly(pending_approval)
        end
      end

      context 'when user does not have admin access' do
        before do
          source.add_developer(user)
        end

        it 'returns empty' do
          expect(finder.execute).to be_empty
        end
      end
    end

    before do
      stub_feature_flags(member_promotion_management: true)
      stub_application_setting(enable_member_promotion_management: true)
    end

    context 'when member promotion management feature is disabled' do
      it 'returns nil' do
        stub_feature_flags(member_promotion_management: false)
        expect(finder.execute).to be_empty
      end
    end

    context 'when member promotion management is disabled in settings' do
      it 'returns nil' do
        stub_application_setting(enable_member_promotion_management: false)
        expect(finder.execute).to be_empty
      end
    end

    context 'when group is provided' do
      let(:member_namespace) { group }
      let(:type) { :for_group_member }

      it_behaves_like 'when feature and settings are enabled'
    end

    context 'when project is provided' do
      let(:source) { project }
      let(:member_namespace) { project.project_namespace }
      let(:type) { :for_project_member }

      it_behaves_like 'when feature and settings are enabled'
    end
  end
end
