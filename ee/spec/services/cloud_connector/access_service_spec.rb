# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::AccessService, feature_category: :cloud_connector do
  let_it_be(:cs_cut_off_date) { "2024-02-15T00:00:00Z" }

  let_it_be(:data) do
    { available_services: [
      { "name" => "code_suggestions", "serviceStartTime" => cs_cut_off_date },
      { "name" => "duo_chat", "serviceStartTime" => nil }
    ] }
  end

  let_it_be(:cloud_connector_access) { create(:cloud_connector_access, data: data) }

  describe '#access_token' do
    subject(:access_token) { described_class.new.access_token(scopes, gitlab_realm) }

    let(:scopes) { [:code_suggestions, :duo_chat] }

    context 'when Self-managed' do
      let(:gitlab_realm) { Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SELF_MANAGED }
      let_it_be(:older_active_token) { create(:service_access_token, :active) }
      let_it_be(:newer_active_token) { create(:service_access_token, :active) }
      let_it_be(:inactive_token) { create(:service_access_token, :expired) }

      it { is_expected.to eq(newer_active_token.token) }
    end

    context 'when .com', :saas do
      let(:gitlab_realm) { Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SAAS }
      let(:encoded_token_string) { 'token_string' }

      it 'returns the constructed token' do
        expect(Gitlab::CloudConnector::SelfIssuedToken).to receive(:new).with(nil, scopes: scopes,
          gitlab_realm: gitlab_realm).and_return(instance_double('Gitlab::CloudConnector::SelfIssuedToken',
            encoded: encoded_token_string))

        expect(access_token).to eq(encoded_token_string)
      end
    end
  end

  describe '#available_services' do
    subject(:available_services) { described_class.new.available_services }

    it 'returns a hash containing all connected services', :aggregate_failures do
      expect(available_services.keys).to match_array([:code_suggestions, :duo_chat])

      expect(available_services[:code_suggestions].name).to eq(:code_suggestions)
      expect(available_services[:code_suggestions].cut_off_date).to eq(cs_cut_off_date)

      expect(available_services[:duo_chat].name).to eq(:duo_chat)
      expect(available_services[:duo_chat].cut_off_date).to be_nil
    end
  end

  describe '#free_access_for?', :freeze_time do
    using RSpec::Parameterized::TableSyntax

    subject(:free_access_for) { described_class.new.free_access_for?(service_name) }

    let_it_be(:test_service_data) do
      { available_services: [
        { "name" => "past_cut_off_date_service", "serviceStartTime" => Time.current - 1.second },
        { "name" => "future_cut_off_date_service", "serviceStartTime" => Time.current + 1.second },
        { "name" => "no_cut_off_date_service", "serviceStartTime" => nil }
      ] }
    end

    let_it_be(:cloud_connector_access) { create(:cloud_connector_access, data: test_service_data) }

    where(:service_name, :org_or_com, :expected_result) do
      :past_cut_off_date_service   | false | false
      :future_cut_off_date_service | false | true
      :no_cut_off_date_service     | false | true
      :unknown                     | false | true
      :past_cut_off_date_service   | true  | false
      :future_cut_off_date_service | true  | false
      :no_cut_off_date_service     | true  | false
      :unknown                     | true  | false
    end

    with_them do
      before do
        allow(Gitlab).to receive(:org_or_com?).and_return(org_or_com)
      end

      it { is_expected.to eq(expected_result) }
    end
  end
end
