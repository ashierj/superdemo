# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::StageCheck, feature_category: :ai_abstraction_layer do
  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_licensed_features(ai_features: true)
  end

  describe ".available?", :saas do
    let(:feature_name) { :summarize_comments }
    let_it_be(:root_group) { create(:group_with_plan, :private, plan: :ultimate_plan) }
    let_it_be(:group) { create(:group, :private, parent: root_group) }

    context 'with experiment feature' do
      before do
        stub_const("#{described_class}::EXPERIMENTAL_FEATURES", [feature_name])
      end

      context 'when experimental setting is false' do
        it 'returns false' do
          root_group.namespace_settings.update!(experiment_features_enabled: false)

          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end

      context 'when experimental setting is true' do
        before do
          root_group.namespace_settings.update!(experiment_features_enabled: true)
        end

        it 'returns true' do
          expect(described_class.available?(group, feature_name)).to eq(true)
        end

        context 'when not on a plan with ai features licensed' do
          before do
            stub_licensed_features(ai_features: false)
          end

          it 'returns false' do
            expect(described_class.available?(group, feature_name)).to eq(false)
          end
        end
      end
    end

    context 'with beta feature' do
      before do
        stub_const("#{described_class}::BETA_FEATURES", [feature_name])
      end

      context 'when experimental setting is false' do
        it 'returns false' do
          root_group.namespace_settings.update!(experiment_features_enabled: false)

          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end

      context 'when experimental setting is true' do
        it 'returns true' do
          root_group.namespace_settings.update!(experiment_features_enabled: true)

          expect(described_class.available?(group, feature_name)).to eq(true)
        end

        context 'when not on a plan with ai features licensed' do
          before do
            stub_licensed_features(ai_features: false)
          end

          it 'returns false' do
            expect(described_class.available?(group, feature_name)).to eq(false)
          end
        end
      end
    end
  end
end
