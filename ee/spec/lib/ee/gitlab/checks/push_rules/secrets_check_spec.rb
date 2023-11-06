# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRules::SecretsCheck, feature_category: :secret_detection do
  include_context 'push rules checks context'

  let_it_be(:push_rule) { create(:push_rule) }

  describe '#validate!' do
    it_behaves_like 'check ignored when push rule unlicensed'
    it_behaves_like 'use predefined push rules'

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
