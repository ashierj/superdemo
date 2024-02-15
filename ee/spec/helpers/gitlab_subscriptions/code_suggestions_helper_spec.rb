# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CodeSuggestionsHelper, feature_category: :seat_cost_management do
  include SubscriptionPortalHelper

  describe '#code_suggestions_available?' do
    context 'when GitLab is SaaS' do
      let_it_be(:namespace) { build_stubbed(:group) }

      before do
        stub_saas_features(gitlab_com_subscriptions: true)
      end

      context 'when SaaS feature flag is globally enabled' do
        it 'returns true' do
          expect(helper.code_suggestions_available?(namespace)).to be_truthy
        end
      end

      context 'when SaaS feature flag is globally disabled' do
        before do
          stub_feature_flags(hamilton_seat_management: false)
        end

        it 'returns false' do
          expect(helper.code_suggestions_available?(namespace)).to be_falsy
        end

        context 'when SaaS feature flag is enabled for a specific namespace' do
          before do
            stub_feature_flags(hamilton_seat_management: namespace)
          end

          it 'returns true' do
            expect(helper.code_suggestions_available?(namespace)).to be_truthy
          end
        end
      end
    end

    context 'when GitLab is self-managed' do
      before do
        stub_saas_features(gitlab_com_subscriptions: false)
      end

      context 'when self-managed feature flag is enabled' do
        it 'returns true' do
          expect(helper.code_suggestions_available?).to be_truthy
        end
      end

      context 'when self-managed feature flag is disabled' do
        before do
          stub_feature_flags(self_managed_code_suggestions: false)
        end

        it 'returns false' do
          expect(helper.code_suggestions_available?).to be_falsy
        end
      end
    end
  end

  describe '#add_duo_pro_seats_url' do
    let(:subscription_name) { 'A-S000XXX' }
    let(:env_value) { nil }

    before do
      stub_env('CUSTOMER_PORTAL_URL', env_value)
    end

    context 'when code suggestions are not available' do
      before do
        allow(helper).to receive(:code_suggestions_available?).and_return false
      end

      it 'returns nil' do
        expect(helper.add_duo_pro_seats_url(subscription_name)).to eq nil
      end
    end

    context 'when code suggestions are available' do
      it 'returns expected url' do
        expected_url = "#{staging_customers_url}/gitlab/namespaces/#{subscription_name}/duo_pro_seats"
        expect(helper.add_duo_pro_seats_url(subscription_name)).to eq expected_url
      end
    end
  end
end
