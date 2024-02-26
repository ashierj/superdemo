# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CloudConnector, feature_category: :cloud_connector do
  describe '#gitlab_realm' do
    subject { described_class.gitlab_realm }

    context 'when the current instance is gitlab.com', :saas do
      it { is_expected.to eq(described_class::GITLAB_REALM_SAAS) }
    end

    context 'when the current instance is not saas' do
      it { is_expected.to eq(described_class::GITLAB_REALM_SELF_MANAGED) }
    end
  end
end
