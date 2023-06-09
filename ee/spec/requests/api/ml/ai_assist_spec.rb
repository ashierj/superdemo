# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::AiAssist, feature_category: :code_suggestions do
  let(:current_user) { nil }
  let(:api_feature_flag) { true }
  let(:access_code_suggestions) { true }
  let(:third_party_ai_features_enabled) { false }
  let(:allowed_group) do
    create(:group_with_plan, plan: nil).tap do |record|
      record.add_owner(current_user)
      record.update_attribute(:third_party_ai_features_enabled, third_party_ai_features_enabled)
    end
  end

  shared_examples 'a response' do |result, body = nil|
    it "returns #{result} response", :aggregate_failures do
      allowed_group

      get_api

      expect(response).to have_gitlab_http_status(result)

      expect(json_response).to eq(body) if body
    end
  end

  describe 'GET /ml/ai-assist user_is_allowed' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_feature_flags(ai_assist_api: api_feature_flag)
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(an_instance_of(User), :access_code_suggestions, :global)
        .and_return(access_code_suggestions)
    end

    subject(:get_api) { get api('/ml/ai-assist', current_user) }

    context 'when user not logged in' do
      let(:current_user) { nil }

      include_examples 'a response', :unauthorized
    end

    context 'when user is logged in' do
      let(:current_user) { create(:user) }

      context 'when API feature flag is disabled' do
        let(:api_feature_flag) { false }

        include_examples 'a response', :not_found, "message" => "404 Not Found"
      end

      context 'with no access to code suggestions' do
        let(:access_code_suggestions) { false }

        include_examples 'a response', :not_found, "message" => "404 Not Found"
      end

      context 'with access to code suggestions' do
        context 'with third party ai features disabled' do
          include_examples 'a response',
            :ok,
            "third_party_ai_features_enabled" => false,
            "user_is_allowed" => true
        end

        context 'with third party ai features enabled' do
          let(:third_party_ai_features_enabled) { true }

          include_examples 'a response',
            :ok,
            "third_party_ai_features_enabled" => true,
            "user_is_allowed" => true
        end
      end
    end
  end
end
