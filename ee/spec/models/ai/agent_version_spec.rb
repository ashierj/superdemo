# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AgentVersion, feature_category: :mlops do
  let_it_be(:base_project) { create(:project) }
  let_it_be(:agent) { create(:ai_agent, project: base_project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:agent) }
  end

  describe 'validation' do
    subject { build(:ai_agent_version) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:agent) }
    it { is_expected.to validate_presence_of(:prompt) }
    it { is_expected.to validate_length_of(:prompt).is_at_most(5000) }

    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_length_of(:model).is_at_most(255) }
    it { is_expected.to be_valid }

    describe 'agent' do
      context 'when project is different' do
        subject(:errors) do
          mv = described_class.new(agent: agent, project: agent.project)
          mv.validate
          mv.errors
        end

        before do
          allow(agent).to receive(:project_id).and_return(non_existing_record_id)
        end

        it { expect(errors[:agent]).to include('agent project must be the same') }
      end
    end
  end
end
