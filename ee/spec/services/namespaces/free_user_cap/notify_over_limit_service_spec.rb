# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::NotifyOverLimitService, feature_category: :measurement_and_locking do
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_owner(create(:owner))
    group.add_owner(create(:owner))
  end

  describe '#execute', :saas do
    subject(:execute) { described_class.new(group).execute }

    it 'records the time of notification in free_user_cap_over_limit_notified_at' do
      group.owners.each do |owner|
        expect(::Namespaces::FreeUserCapMailer).to receive(:over_limit_email).with(owner, group).once.and_call_original
      end

      execute

      expect(execute).to be_a(ServiceResponse)
      expect(execute).to be_success
    end

    context 'with error condition' do
      it 'rescues to a ServiceResponse' do
        expect(::Namespaces::FreeUserCapMailer).to receive(:over_limit_email).and_raise(StandardError, '_error_')

        execute

        expect(execute).to be_a(ServiceResponse)
        expect(execute).not_to be_success
      end
    end
  end

  describe '.execute' do
    it 'emails the owner(s) of the group' do
      group.owners.each do |owner|
        expect(::Namespaces::FreeUserCapMailer).to receive(:over_limit_email).with(owner, group).once.and_call_original
      end

      described_class.execute(group)
    end
  end
end
