# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CodeSuggestionsHelper, feature_category: :seat_cost_management do
  describe '#code_suggestions_available?' do
    context 'when GitLab is SaaS' do
      let_it_be(:namespace) { build_stubbed(:group) }

      before do
        stub_saas_features(gitlab_saas_subscriptions: true)
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
        stub_saas_features(gitlab_saas_subscriptions: false)
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

      context 'when license' do
        let(:plan) { nil }
        let(:license) { build(:license, plan: plan) }

        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'when instance has a paid license' do
          where(:license_plan) do
            [License::STARTER_PLAN, License::PREMIUM_PLAN, License::ULTIMATE_PLAN]
          end

          with_them do
            let(:plan) { license_plan }

            it 'returns false' do
              expect(helper.code_suggestions_available?).to be_truthy
            end
          end
        end

        context 'when instance has a non-paid license' do
          let(:plan) { License::LEGACY_LICENSE_TYPE }

          it 'returns false' do
            expect(helper.code_suggestions_available?).to be_falsy
          end
        end

        context 'when instance does not have a paid license' do
          let(:license) { nil }

          it 'returns false' do
            expect(helper.code_suggestions_available?).to be_falsy
          end
        end
      end
    end
  end
end
