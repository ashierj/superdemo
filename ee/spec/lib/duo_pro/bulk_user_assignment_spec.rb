# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DuoPro::BulkUserAssignment, feature_category: :purchase do
  describe '#initialize' do
    subject(:bulk_assignment) { described_class.new([], nil) }

    it 'initializes with the correct attributes' do
      expect(bulk_assignment.usernames).to eq([])
      expect(bulk_assignment.add_on_purchase).to be_nil
      expect(bulk_assignment.successful_assignments).to eq([])
      expect(bulk_assignment.failed_assignments).to eq([])
    end
  end

  describe '#execute' do
    let(:add_on) { create(:gitlab_subscription_add_on) }
    let(:usernames) { User.pluck(:username) + ['code_suggestions_not_found_username'] }

    before do
      create(:user, username: 'code_suggestions_active_user1')
      create(:user, username: 'code_suggestions_active_user2')
      create(:user, username: 'code_suggestions_active_user3')
      create(:user, username: 'code_suggestions_extra_user1')
      create(:user, username: 'code_suggestions_extra_user2')
      create(:user, :blocked, username: 'code_suggestions_blocked_user')
      create(:user, :banned, username: 'code_suggestions_banned_user')
      create(:user, :bot, username: 'code_suggestions_bot_user')
      create(:user, :ghost, username: 'code_suggestions_ghost_user')
    end

    context 'when the AddOn is not purchased' do
      it 'returns a message indicating AddOn not purchased' do
        results = described_class.new([], nil).execute
        expect(results).to eq('AddOn not purchased')
      end
    end

    context 'when the AddOn is purchased' do
      let(:add_on_purchase) do
        create(:gitlab_subscription_add_on_purchase, :self_managed, quantity: 10, add_on: add_on)
      end

      subject(:bulk_assignment) { described_class.new(usernames, add_on_purchase) }

      context 'with enough seats' do
        it 'returns success and failed assignments' do
          results = bulk_assignment.execute

          expect(results[:successful_assignments]).to eq([
            "User assigned: code_suggestions_active_user1",
            "User assigned: code_suggestions_active_user2",
            "User assigned: code_suggestions_active_user3",
            "User assigned: code_suggestions_extra_user1",
            "User assigned: code_suggestions_extra_user2"
          ])

          expect(results[:failed_assignments]).to eq([
            "Failed to assign seat to user: code_suggestions_blocked_user, Errors: [\"INVALID_USER_MEMBERSHIP\"]",
            "Failed to assign seat to user: code_suggestions_banned_user, Errors: [\"INVALID_USER_MEMBERSHIP\"]",
            "Failed to assign seat to user: code_suggestions_bot_user, Errors: [\"INVALID_USER_MEMBERSHIP\"]",
            "Failed to assign seat to user: code_suggestions_ghost_user, Errors: [\"INVALID_USER_MEMBERSHIP\"]",
            "User is not found: code_suggestions_not_found_username"
          ])
        end
      end

      context 'with not enough seats' do
        let(:add_on_purchase) do
          create(:gitlab_subscription_add_on_purchase, :self_managed, quantity: 3, add_on: add_on)
        end

        it 'returns success and failed assignments and stops execution' do
          results = bulk_assignment.execute

          expect(results[:successful_assignments]).to eq(
            ["User assigned: code_suggestions_active_user1",
              "User assigned: code_suggestions_active_user2",
              "User assigned: code_suggestions_active_user3"])

          expect(results[:failed_assignments]).to eq(
            ["Failed to assign seat to user: code_suggestions_extra_user1, Errors: [\"NO_SEATS_AVAILABLE\"]",
              "##No seats are left; users starting from @code_suggestions_extra_user1 onwards were not assigned.##"])
        end
      end
    end
  end
end
