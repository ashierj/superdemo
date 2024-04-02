# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::AvailableServiceData, feature_category: :cloud_connector do
  let_it_be(:cut_off_date) { 1.day.ago }
  let_it_be(:purchased_add_ons) { %w[code_suggestions] }

  describe '#free_access?' do
    subject(:access_token) { described_class.new(:duo_chat, cut_off_date, nil).free_access? }

    context 'when cut_off_date is in the past' do
      let_it_be(:cut_off_date) { 1.day.ago }

      it { is_expected.to be false }
    end

    context 'when cut_off_date is in the future' do
      let_it_be(:cut_off_date) { 1.day.from_now }

      it { is_expected.to be true }
    end
  end

  describe '#allowed_for?', :redis do
    let_it_be(:gitlab_add_on) { create(:gitlab_subscription_add_on) }
    let_it_be(:user) { create(:user) }

    let_it_be(:expired_gitlab_purchase) do
      create(:gitlab_subscription_add_on_purchase, expires_on: 1.day.ago, add_on: gitlab_add_on)
    end

    let_it_be_with_reload(:active_gitlab_purchase) do
      create(:gitlab_subscription_add_on_purchase, :self_managed, add_on: gitlab_add_on)
    end

    subject(:allowed_for?) { described_class.new(:duo_chat, cut_off_date, purchased_add_ons).allowed_for?(user) }

    context 'when the user has an active assigned seat' do
      before do
        create(
          :gitlab_subscription_user_add_on_assignment,
          user: user,
          add_on_purchase: active_gitlab_purchase
        )
      end

      it { is_expected.to be true }

      it 'caches the available services' do
        expect(GitlabSubscriptions::UserAddOnAssignment)
          .to receive_message_chain(:by_user, :for_active_add_on_purchases, :any?)

        2.times do
          allowed_for?
        end
      end
    end

    context 'when the user has an expired assigned duo pro seat' do
      before do
        create(
          :gitlab_subscription_user_add_on_assignment,
          user: user,
          add_on_purchase: expired_gitlab_purchase
        )
      end

      it { is_expected.to be false }
    end

    context 'when the user has no add on seat assignments' do
      it { is_expected.to be false }
    end
  end

  describe '#name' do
    subject(:name) { described_class.new(:duo_chat, cut_off_date, purchased_add_ons).name }

    it { is_expected.to eq(:duo_chat) }
  end

  describe '#access_token' do
    subject(:access_token) { described_class.new(:duo_chat, nil, nil).access_token }

    let_it_be(:older_active_token) { create(:service_access_token, :active) }
    let_it_be(:newer_active_token) { create(:service_access_token, :active) }
    let_it_be(:inactive_token) { create(:service_access_token, :expired) }

    it { is_expected.to eq(newer_active_token.token) }
  end
end
