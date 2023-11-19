# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreamSetting, type: :model, feature_category: :value_stream_management do
  let_it_be(:value_stream_setting) { create(:cycle_analytics_value_stream_setting) }

  describe 'associations' do
    it { is_expected.to belong_to(:value_stream) }
  end

  describe 'validations' do
    it {
      is_expected.not_to allow_value(Array.new(described_class::MAX_PROJECT_IDS_FILTER + 1, 1))
        .for(:project_ids_filter)
        .with_message('Maximum projects allowed in the filter is 100')
    }

    it { is_expected.to allow_value(Array.new(described_class::MAX_PROJECT_IDS_FILTER, 1)).for(:project_ids_filter) }

    context 'for project_ids_filter' do
      let(:value_stream_setting) do
        build(
          :cycle_analytics_value_stream_setting,
          value_stream: value_stream,
          project_ids_filter: [1]
        )
      end

      context 'when value stream belongs to a project' do
        let_it_be(:value_stream) do
          create(:cycle_analytics_value_stream, namespace: create(:project).project_namespace)
        end

        it 'is invalid' do
          expect(value_stream_setting).not_to be_valid
          expect(value_stream_setting.errors[:project_ids_filter])
            .to include('Can only be present for group level value streams')
        end
      end

      context 'when value stream belongs to a group' do
        let_it_be(:value_stream) do
          create(:cycle_analytics_value_stream, namespace: create(:group))
        end

        it 'is valid' do
          expect(value_stream_setting).to be_valid
        end
      end
    end
  end

  it 'persists project ids filter' do
    value_stream_setting =
      create(:cycle_analytics_value_stream_setting, project_ids_filter: [1, 2, 3])

    expect(value_stream_setting.project_ids_filter).to eq([1, 2, 3])
  end
end
