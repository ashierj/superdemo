# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::StageCheck, :saas, feature_category: :ai_abstraction_layer do
  let(:feature_name) { :summarize_comments }
  let_it_be(:root_group) { create(:group_with_plan, :private, plan: :ultimate_plan) }
  let_it_be(:group) { create(:group, :private, parent: root_group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  describe ".available?", :saas do
    using RSpec::Parameterized::TableSyntax

    where(:container, :feature_type) do
      ref(:group)   | "EXPERIMENTAL"
      ref(:group)   | "BETA"
      ref(:project) | "EXPERIMENTAL"
      ref(:project) | "BETA"
    end

    with_them do
      before do
        stub_const("#{described_class}::#{feature_type}_FEATURES", [feature_name])
        stub_ee_application_setting(should_check_namespace_plan: true)
        stub_licensed_features(experimental_features: true, ai_features: true)
      end

      context 'when experimental setting is false' do
        it 'returns false' do
          root_group.namespace_settings.update!(experiment_features_enabled: false)
          expect(described_class.available?(container, feature_name)).to eq(false)
        end
      end

      context 'when experimental setting is true' do
        before do
          root_group.namespace_settings.update!(experiment_features_enabled: true)
        end

        it 'returns true' do
          expect(described_class.available?(container, feature_name)).to eq(true)
        end

        context 'for a project in a personal namespace' do
          let_it_be(:user) { create(:user) }
          let_it_be(:project) { create(:project, namespace: user.namespace) }

          it 'returns false' do
            expect(described_class.available?(project, feature_name)).to eq(false)
          end
        end

        context 'with an invalid feature name' do
          it 'returns false' do
            expect(described_class.available?(container, :invalid_feature_name)).to eq(false)
          end
        end

        context 'when not on a plan with ai features licensed' do
          before do
            stub_licensed_features(ai_features: false)
          end

          it 'returns false' do
            expect(described_class.available?(container, feature_name)).to eq(false)
          end
        end
      end
    end
  end
end
