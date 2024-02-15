# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::CloudConnector, feature_category: :cloud_connector do
  subject(:helper) do
    Class.new do
      include API::Helpers::CloudConnector
    end.new
  end

  let_it_be(:user) { build(:user, id: 1) }

  describe '#cloud_connector_headers' do
    it 'generates a hash with the required fields based on the user' do
      expect(helper.cloud_connector_headers(user)).to match(
        {
          'X-Gitlab-Instance-Id' => an_instance_of(String),
          'X-Gitlab-Global-User-Id' => an_instance_of(String),
          'X-Gitlab-Realm' => Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SELF_MANAGED
        }
      )
    end
  end

  describe '#gitlab_realm' do
    context 'when the current instance is gitlab.com', :saas do
      it 'returns Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SAAS' do
        expect(helper.gitlab_realm).to eq(Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SAAS)
      end
    end

    context 'when the current instance is not saas' do
      it 'returns Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SELF_MANAGED' do
        expect(helper.gitlab_realm).to eq(Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SELF_MANAGED)
      end
    end
  end
end
