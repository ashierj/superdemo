# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::SubscriptionHelper, feature_category: :seat_cost_management do
  describe '#gitlab_saas?' do
    context 'when GitLab is SaaS' do
      before do
        stub_saas_features(gitlab_saas_subscriptions: true)
      end

      it 'returns true' do
        expect(helper.gitlab_saas?).to be_truthy
      end
    end

    context 'when GitLab is not SaaS' do
      before do
        stub_saas_features(gitlab_saas_subscriptions: false)
      end

      it 'returns false' do
        expect(helper.gitlab_saas?).to be_falsy
      end
    end
  end

  describe '#gitlab_sm?' do
    context 'when GitLab is self-managed' do
      before do
        stub_saas_features(gitlab_saas_subscriptions: false)
      end

      it 'returns true' do
        expect(helper.gitlab_sm?).to be_truthy
      end
    end

    context 'when GitLab is not self-managed' do
      before do
        stub_saas_features(gitlab_saas_subscriptions: true)
      end

      it 'returns false' do
        expect(helper.gitlab_sm?).to be_falsy
      end
    end
  end
end
