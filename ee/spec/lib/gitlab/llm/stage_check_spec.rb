# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::StageCheck, feature_category: :ai_abstraction_layer do
  let(:feature_name) { :summarize_comments }

  describe ".available?" do
    using RSpec::Parameterized::TableSyntax

    # TODO: refactor whole spec file once duo_chat_ga feature flag is removed
    # Due to time constraint, here we only test the only GA feature (chat)
    context 'with chat feature' do
      let(:feature_name) { :chat }

      context 'when gitlab.com', :saas do
        let_it_be(:root_group) { create(:group_with_plan, :private, plan: :ultimate_plan) }
        let_it_be(:group) { create(:group, :private, parent: root_group) }
        let_it_be_with_reload(:project) { create(:project, group: group) }

        where(:licensed_feature, :duo_chat_ga, :namespace_experiment_features_enabled, :expectation) do
          false | false | false | false
          false | false | true  | false
          false | true  | false | false
          false | true  | true  | false
          true  | false | false | false
          true  | false | true  | true
          true  | true  | false | true
          true  | true  | true  | true
        end

        with_them do
          before do
            stub_licensed_features(experimental_features: true, ai_chat: licensed_feature)
            stub_feature_flags(duo_chat_ga: duo_chat_ga)
            root_group.namespace_settings.update!(experiment_features_enabled: namespace_experiment_features_enabled)
          end

          it 'handles project' do
            expect(described_class.available?(project, feature_name)).to eq(expectation)
          end

          it 'handles group' do
            expect(described_class.available?(group, feature_name)).to eq(expectation)
          end
        end
      end

      context 'when not gitlab.com' do
        let_it_be(:root_group) { create(:group, :private) }
        let_it_be(:group) { create(:group, :private, parent: root_group) }
        let_it_be_with_reload(:project) { create(:project, group: group) }

        where(:licensed_feature, :duo_chat_ga, :namespace_experiment_features_enabled, :expectation) do
          false | false | false | false
          false | false | true  | false
          false | true  | false | false
          false | true  | true  | false
          true  | false | false | false
          true  | false | true  | true
          true  | true  | false | true
          true  | true  | true  | true
        end

        with_them do
          before do
            stub_licensed_features(experimental_features: true, ai_chat: licensed_feature)
            stub_feature_flags(duo_chat_ga: duo_chat_ga)
            root_group.namespace_settings.update!(experiment_features_enabled: namespace_experiment_features_enabled)
          end

          it 'handles project' do
            expect(described_class.available?(project, feature_name)).to eq(expectation)
          end

          it 'handles group' do
            expect(described_class.available?(group, feature_name)).to eq(expectation)
          end
        end
      end
    end

    context 'when gitlab.com', :saas do
      let_it_be(:root_group) { create(:group_with_plan, :private, plan: :ultimate_plan) }
      let_it_be(:group) { create(:group, :private, parent: root_group) }
      let_it_be_with_reload(:project) { create(:project, group: group) }

      where(:container, :feature_type) do
        ref(:group)   | "EXPERIMENTAL"
        ref(:group)   | "BETA"
        ref(:project) | "EXPERIMENTAL"
        ref(:project) | "BETA"
      end

      with_them do
        before do
          stub_const("#{described_class}::#{feature_type}_FEATURES", [feature_name])
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

      context 'with premium plan' do
        let_it_be(:root_group) { create(:group_with_plan, :private, plan: :premium_plan) }

        before do
          stub_ee_application_setting(should_check_namespace_plan: true)
          stub_licensed_features(ai_chat: true)
          root_group.namespace_settings.update!(experiment_features_enabled: true)
          stub_const("#{described_class}::BETA_FEATURES", [feature_name])
        end

        it 'returns false' do
          expect(described_class.available?(project, feature_name)).to eq(false)
        end
      end
    end

    context 'when not gitlab.com' do
      let_it_be(:root_group) { create(:group, :private) }
      let_it_be(:group) { create(:group, :private, parent: root_group) }
      let_it_be_with_reload(:project) { create(:project, group: group) }

      where(:container, :feature_type) do
        ref(:group)   | "EXPERIMENTAL"
        ref(:group)   | "BETA"
        ref(:project) | "EXPERIMENTAL"
        ref(:project) | "BETA"
      end

      with_them do
        before do
          stub_const("#{described_class}::#{feature_type}_FEATURES", [feature_name])
        end

        context 'when instance has ai_features license' do
          before do
            stub_licensed_features(ai_features: true)
          end

          context 'when experimental features enabled setting is true' do
            it 'returns expectation' do
              root_group.namespace_settings.update!(experiment_features_enabled: true)

              # currently, experimental AI features are only available on gitlab.com
              expectation = feature_type != "EXPERIMENTAL"
              expect(described_class.available?(container, feature_name)).to eq(expectation)
            end
          end

          context 'when experimental features enabled setting is false' do
            it 'returns false' do
              root_group.namespace_settings.update!(experiment_features_enabled: false)

              expect(described_class.available?(container, feature_name)).to eq(false)
            end
          end
        end
      end
    end
  end
end
