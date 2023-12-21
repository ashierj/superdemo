# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportDetailsEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let_it_be(:report) { create(:abuse_report) }
  let_it_be(:user) { report.user }

  let(:entity) do
    described_class.new(report)
  end

  subject(:entity_hash) { entity.as_json }

  describe 'users credit card' do
    let(:credit_card_hash) { entity_hash[:user][:credit_card] }

    context 'when the user has no verified credit card' do
      it 'does not expose the credit card' do
        expect(credit_card_hash).to be_nil
      end
    end

    context 'when the user does have a verified credit card' do
      before do
        create(:credit_card_validation, user: user)
      end

      it 'exposes the credit card' do
        expect(credit_card_hash).to include({
          similar_records_count: 1,
          card_matches_link: card_match_admin_user_path(user)
        })
      end

      context 'when not on ee', unless: Gitlab.ee? do
        it 'does not include the path to the admin card matches page' do
          expect(credit_card_hash[:card_matches_link]).to be_nil
        end
      end

      context 'when on ee', if: Gitlab.ee? do
        it 'includes the path to the admin card matches page' do
          expect(credit_card_hash[:card_matches_link]).not_to be_nil
        end
      end
    end
  end

  describe 'users phone number' do
    let(:phone_number_hash) { entity_hash[:user][:phone_number] }

    context 'when the user has no phone number validation attempts' do
      it 'does not expose the phone number' do
        expect(phone_number_hash).to be_nil
      end
    end

    context 'when the user does have phone number validation attempts' do
      before do
        create(:phone_number_validation, user: user)
      end

      it 'exposes the phone number' do
        expect(phone_number_hash).to include({
          similar_records_count: 1,
          phone_matches_link: phone_match_admin_user_path(user)
        })
      end
    end
  end
end
