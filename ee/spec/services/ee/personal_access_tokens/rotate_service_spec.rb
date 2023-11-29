# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::RotateService, feature_category: :system_access do
  let_it_be(:token, reload: true) { create(:personal_access_token) }

  subject(:response) { described_class.new(token.user, token).execute }

  context 'when max lifetime is set to less than 1 week' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:max_personal_access_token_lifetime_from_now)
        .and_return(2.days.from_now)
    end

    let_it_be(:token, reload: true) { create(:personal_access_token) }

    subject(:response) { described_class.new(token.user, token).execute }

    it "rotates user's own token", :freeze_time do
      expect(response).to be_success

      new_token = response.payload[:personal_access_token]

      expect(new_token.token).not_to eq(token.token)
      expect(new_token.expires_at).to eq(Date.today + 2.days)
      expect(new_token.user).to eq(token.user)
    end
  end

  context 'when max lifetime is set to more than 1 week' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:max_personal_access_token_lifetime_from_now)
        .and_return(10.days.from_now)
    end

    let_it_be(:token, reload: true) { create(:personal_access_token) }

    subject(:response) { described_class.new(token.user, token).execute }

    it "rotates user's own token", :freeze_time do
      expect(response).to be_success

      new_token = response.payload[:personal_access_token]

      expect(new_token.token).not_to eq(token.token)
      expect(new_token.expires_at).not_to eq(Date.today + 10.days)
      expect(new_token.expires_at).to eq(Date.today + 7.days)
      expect(new_token.user).to eq(token.user)
    end
  end
end
