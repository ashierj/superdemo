# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EpicWorkItemSync::Diff, feature_category: :team_planning do
  describe '#attributes' do
    subject(:attributes) { described_class.new(epic, work_item).attributes }

    let(:epic) { create(:epic, :with_synced_work_item) }
    let(:work_item) { epic.work_item }

    context 'when epic and work item are equal' do
      it { is_expected.to be_empty }
    end

    describe 'base attributes' do
      context 'when epic and work base attributes are not equal' do
        let(:title) { "Other title" }
        let(:expected_differences) { %w[title lock_version] }

        before do
          epic.update!(title: title)
        end

        it 'returns a list of attributes that are different' do
          expect(attributes).to match_array(expected_differences)
        end
      end

      context 'when updated_at is within a 1 second range' do
        let_it_be(:updated_at) { Time.current }

        before do
          epic.update!(updated_at: updated_at)
          work_item.update!(updated_at: updated_at + 0.9.seconds)
        end

        it { is_expected.to be_empty }
      end

      context 'when updated_at exceeds 1 second difference' do
        let_it_be(:updated_at) { Time.current }

        before do
          epic.update!(updated_at: updated_at)
          work_item.update!(updated_at: updated_at + 1.second)
        end

        it { is_expected.to include("updated_at") }
      end
    end

    describe 'namespace' do
      context 'when epic has a different group_id than the work item namespace_id' do
        before do
          epic.update!(group: create(:group))
        end

        it { is_expected.to include("namespace") }
      end
    end

    describe 'color' do
      context 'when epic color is equal to work item color' do
        before do
          create(:color, work_item: work_item, color: '#0052cc')
          epic.update!(color: '#0052cc')
        end

        it { is_expected.not_to include("color") }
      end

      context 'when epic color is the default color and work item color is nil' do
        before do
          epic.update!(color: Epic::DEFAULT_COLOR)
        end

        it { is_expected.to be_empty }
      end

      context 'when epic color is not the default color and work item color is nil' do
        before do
          epic.update!(color: '#123456')
        end

        it { is_expected.to include("color") }
      end
    end
  end
end
