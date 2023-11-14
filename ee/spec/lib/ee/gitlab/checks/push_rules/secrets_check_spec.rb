# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRules::SecretsCheck, feature_category: :secret_detection do
  include_context 'push rules checks context'

  let_it_be(:push_rule) { create(:push_rule) }

  describe '#validate!' do
    it_behaves_like 'check ignored when push rule unlicensed'

    context 'when application settings is disabled' do
      before do
        Gitlab::CurrentSettings.update!(pre_receive_secret_detection_enabled: false)
      end

      it 'skips the check' do
        expect(subject.validate!).to be_nil
      end
    end

    context 'when application settings is enabled' do
      before do
        Gitlab::CurrentSettings.update!(pre_receive_secret_detection_enabled: true)
      end

      it_behaves_like 'use predefined push rules'

      context 'when instance is dedicated' do
        before do
          Gitlab::CurrentSettings.update!(gitlab_dedicated_instance: true)
        end

        context 'when license is not ultimate' do
          it 'skips the check' do
            expect(subject.validate!).to be_nil
          end
        end

        context 'when license is ultimate' do
          before do
            stub_licensed_features(pre_receive_secret_detection: true)
          end

          it 'returns without raising errors' do
            # Since the check does nothing at the moment, it just execute without raising errors
            expect { subject.validate! }.not_to raise_error
          end
        end
      end

      context 'when instance is not dedicated' do
        before do
          Gitlab::CurrentSettings.update!(gitlab_dedicated_instance: false)
        end

        context 'when license is not ultimate' do
          it 'skips the check' do
            expect(subject.validate!).to be_nil
          end
        end

        context 'when license is ultimate' do
          before do
            stub_licensed_features(pre_receive_secret_detection: true)
          end

          it 'returns without raising errors' do
            # Since the check does nothing at the moment, it just execute without raising errors
            expect { subject.validate! }.not_to raise_error
          end
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(pre_receive_secret_detection_push_check: false)
          end

          it 'skips the check' do
            expect(subject.validate!).to be_nil
          end
        end
      end
    end
  end
end
