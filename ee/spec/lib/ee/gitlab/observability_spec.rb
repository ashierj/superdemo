# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability, feature_category: :tracing do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '.tracing_url' do
    subject { described_class.tracing_url(project) }

    it { is_expected.to eq("#{described_class.observability_url}/query/#{group.id}/#{project.id}/v1/traces") }
  end
end
