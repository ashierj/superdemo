# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Notes, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item, :objective, discussion_locked: true) }

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:discussion_locked) }
  end

  describe '.quick_action_commands' do
    subject { described_class.quick_action_commands }

    it { is_expected.to match_array([:lock, :unlock]) }
  end

  describe '#discussion_locked' do
    subject { described_class.new(work_item).discussion_locked }

    it { is_expected.to eq(work_item.discussion_locked) }
  end
end
