# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::BlockSeatOverages::Enforcement, feature_category: :consumables_cost_management do
  include ReactiveCachingHelpers

  describe '#git_check_seat_overage!', :saas do
    let_it_be(:group, refind: true) { create(:group) }
    let_it_be(:subscription) { create(:gitlab_subscription, :premium, namespace: group, seats: 1) }

    let(:over_seats_error_message) { /Your top-level group is over the number of seats in its subscription/ }

    subject(:enforcement) { described_class.new(group) }

    before_all do
      group.add_developer(create(:user))
    end

    before do
      synchronous_reactive_cache(group)
    end

    context 'when block seat overages is enabled' do
      it 'raises the passed error when the group is over the number of seats in its subscription' do
        group.add_developer(create(:user))

        expect do
          enforcement.git_check_seat_overage!(StandardError)
        end.to raise_error(StandardError, over_seats_error_message)
      end

      it 'does not raise an error when the group is within the number of seats in its subscription' do
        expect { enforcement.git_check_seat_overage!(StandardError) }.not_to raise_error
      end
    end

    context 'when block seat overages is disabled' do
      before do
        stub_feature_flags(block_seat_overages: false)
      end

      it 'does not raise an error even when the group is over the number of seats in its subscription' do
        group.add_developer(create(:user))

        expect { enforcement.git_check_seat_overage!(StandardError) }.not_to raise_error
      end
    end
  end
end
