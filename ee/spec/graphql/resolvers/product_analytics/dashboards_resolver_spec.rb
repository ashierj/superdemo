# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProductAnalytics::DashboardsResolver, feature_category: :product_analytics_data_management do
  include GraphqlHelpers

  describe '#resolve' do
    subject(:result) { resolve(described_class, obj: project, ctx: { current_user: user }, args: { slug: slug }) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) do
      create(:project, :with_product_analytics_dashboard, group: create(:group))
    end

    let(:slug) { nil }

    before do
      allow(Gitlab::CurrentSettings).to receive(:product_analytics_enabled?).and_return(true)
      allow(project.group.root_ancestor.namespace_settings).to receive(:experiment_settings_allowed?).and_return(true)
      stub_licensed_features(product_analytics: true, project_level_analytics_dashboard: false)
      stub_feature_flags(ai_impact_analytics_dashboard: false)
      project.group.root_ancestor.namespace_settings.update!(experiment_features_enabled: true,
        product_analytics_enabled: true)
      project.project_setting.update!(product_analytics_instrumentation_key: "key")
      allow_next_instance_of(::ProductAnalytics::CubeDataQueryService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: {
          'results' => [{ "data" => [{ "TrackedEvents.count" => "1" }] }]
        }))
      end
    end

    context 'when user has guest access' do
      before do
        project.add_guest(user)
      end

      it { is_expected.to be_nil }

      context 'when slug is provided' do
        let(:slug) { 'dashboard_example_1' }

        it { is_expected.to be_nil }
      end
    end

    context 'when user has developer access' do
      before do
        project.add_developer(user)
      end

      it 'returns all dashboards including hardcoded ones' do
        expect(result).to eq(project.product_analytics_dashboards(user))
        expect(result.size).to eq(3)
      end

      context 'when onboarding is incomplete' do
        before do
          project.project_setting.update!(product_analytics_instrumentation_key: nil)
        end

        it 'returns custom dashboards' do
          expect(result).to eq(project.product_analytics_dashboards(user))
          expect(result.size).to eq(1)
          expect(result.first.title).to eq("Dashboard Example 1")
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(product_analytics_dashboards: false)
        end

        it 'contains only user defined dashboards' do
          expect(result.size).to eq(1)
        end
      end

      context 'when product analytics toggle is disabled' do
        before do
          project.group.root_ancestor.namespace_settings.update!(product_analytics_enabled: false)
        end

        it 'contains only user defined dashboards' do
          expect(result.size).to eq(1)
        end
      end

      context 'when slug matches existing dashboard' do
        context 'when it\'s a custom dashboard' do
          let(:slug) { 'dashboard_example_1' }

          it 'contains only one dashboard and it is the one with the matching slug' do
            expect(result.size).to eq(1)
            expect(result.first.slug).to eq(slug)
          end

          context 'when feature flag is disabled' do
            before do
              stub_feature_flags(product_analytics_dashboards: false)
            end

            it 'still returns the dashboard' do
              expect(result.size).to eq(1)
              expect(result.first.slug).to eq(slug)
            end
          end

          context 'when product analytics toggle is disabled' do
            before do
              project.group.root_ancestor.namespace_settings.update!(product_analytics_enabled: false)
            end

            it 'still returns the dashboard' do
              expect(result.size).to eq(1)
              expect(result.first.slug).to eq(slug)
            end
          end
        end

        context 'when it\'s a built in product analytics dashboard' do
          let(:slug) { 'audience' }

          it 'contains only one dashboard and it is the one with the matching slug' do
            expect(result.size).to eq(1)
            expect(result.first.slug).to eq(slug)
          end

          context 'when feature flag is disabled' do
            before do
              stub_feature_flags(product_analytics_dashboards: false)
            end

            it 'is empty' do
              expect(result.size).to eq(0)
            end
          end

          context 'when product analytics toggle is disabled' do
            before do
              project.group.root_ancestor.namespace_settings.update!(product_analytics_enabled: false)
            end

            it 'is empty' do
              expect(result.size).to eq(0)
            end
          end
        end
      end

      context 'when path does not match existing dashboard' do
        let(:slug) { 'not_a_real_dashboard' }

        it 'returns no dashboard' do
          expect(result).to be_empty
        end
      end
    end
  end
end
