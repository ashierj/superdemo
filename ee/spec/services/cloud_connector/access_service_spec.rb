# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::AccessService, feature_category: :cloud_connector do
  describe '#access_token' do
    subject(:access_token) { described_class.new.access_token(scopes, gitlab_realm) }

    let(:scopes) { [:code_suggestions, :duo_chat] }

    context 'when Self-managed' do
      let(:gitlab_realm) { Gitlab::Ai::AccessToken::GITLAB_REALM_SELF_MANAGED }
      let_it_be(:older_active_token) { create(:service_access_token, :active) }
      let_it_be(:newer_active_token) { create(:service_access_token, :active) }
      let_it_be(:inactive_token) { create(:service_access_token, :expired) }

      it { is_expected.to eq(newer_active_token.token) }
    end

    context 'when SaaS', :saas do
      let(:gitlab_realm) { Gitlab::Ai::AccessToken::GITLAB_REALM_SAAS }
      let(:encoded_token_string) { 'token_string' }

      it 'returns the constructed token' do
        expect(Gitlab::Ai::AccessToken).to receive(:new).with(nil, scopes: scopes,
          gitlab_realm: gitlab_realm).and_return(instance_double('Gitlab::Ai::AccessToken',
            encoded: encoded_token_string))

        expect(access_token).to eq(encoded_token_string)
      end
    end
  end
end
