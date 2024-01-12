# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AgentPresenter, feature_category: :mlops do
  let(:project) { build_stubbed(:project) }
  let(:agent) { build_stubbed(:ai_agent, project: project) }

  describe '#path' do
    subject { agent.present.path }

    it { is_expected.to eq("/#{project.full_path}/-/ml/agents/#{agent.id}") }
  end
end
