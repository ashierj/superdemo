# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRoles::DeleteService, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:member_role) { create(:member_role, :guest, namespace: group) }

  subject(:service) { described_class.new(user) }

  before do
    stub_licensed_features(custom_roles: true)
  end

  describe '#execute' do
    subject(:result) { service.execute(member_role) }

    context 'with unauthorized user' do
      it 'returns an error' do
        expect(result).to be_error
      end
    end

    context 'with owner' do
      before_all do
        group.add_owner(user)
      end

      context 'without existing members' do
        it 'is successful' do
          expect(result).to be_success
        end

        it 'deletes the member role' do
          result

          expect(member_role).to be_destroyed
        end
      end

      context 'when failing to destroy the member role' do
        before do
          allow(member_role).to receive(:destroy).and_return(false)
          errors = ActiveModel::Errors.new(member_role).tap { |e| e.add(:base, 'error message') }
          allow(member_role).to receive(:errors).and_return(errors)
        end

        it 'returns an array including the error message' do
          expect(result).to be_error
          expect(result.message).to match_array(['error message'])
        end
      end
    end
  end
end
