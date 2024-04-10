# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::ContributorCountService, :freeze_time, feature_category: :value_stream_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_developer(user) } }
  let_it_be(:from) { Date.new(2022, 5, 1) }
  let_it_be(:to) { Date.new(2022, 6, 10) }

  let(:current_user) { user }

  subject(:service_response) do
    described_class.new(
      group: group,
      current_user: current_user,
      from: from,
      to: to
    ).execute
  end

  before do
    allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)
  end

  context 'when the clickhouse is not available for analytics' do
    before do
      allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(false)
    end

    it 'returns service error' do
      expect(service_response).to be_error

      message = s_('VsdContributorCount|the ClickHouse data store is not available for this group')
      expect(service_response.message).to eq(message)
    end
  end

  context 'when the user has no access to the group' do
    let(:current_user) { other_user }

    before do
      allow(::Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)
      stub_licensed_features(group_level_analytics_dashboard: true)
    end

    it 'returns service error' do
      expect(service_response).to be_error

      message = s_('404|Not found')
      expect(service_response.message).to eq(message)
    end
  end

  context 'when the group is not licensed' do
    before do
      allow(::Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)
      stub_licensed_features(group_level_analytics_dashboard: false)
    end

    it 'returns service error' do
      expect(service_response).to be_error

      message = s_('404|Not found')
      expect(service_response.message).to eq(message)
    end
  end

  context 'when the feature is available', :click_house do
    before do
      allow(::Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)
      stub_licensed_features(group_level_analytics_dashboard: true)
    end

    context 'when no data present' do
      it 'returns 0' do
        expect(service_response).to be_success
        expect(service_response[:count]).to eq(0)
      end
    end

    context 'when data present' do
      before do
        clickhouse_fixture(:events, [
          # push event
          { id: 1, path: "#{group.id}/", author_id: 100, target_id: 0, target_type: '', action: 5,
            created_at: from + 5.days, updated_at: from + 5.days },
          # push event same user
          { id: 2, path: "#{group.id}/", author_id: 100, target_id: 0, target_type: '', action: 5,
            created_at: from + 8.days, updated_at: from + 8.days },
          # issue creation event, different user
          { id: 3, path: "#{group.id}/", author_id: 200, target_id: 0, target_type: 'Issue', action: 1,
            created_at: from + 9.days, updated_at: from + 9.days },
          # issue creation event, outside of the date range
          { id: 4, path: "#{group.id}/", author_id: 200, target_id: 0, target_type: 'Issue', action: 1,
            created_at: from + 5.years, updated_at: from + 5.years },
          # issue creation event, for a different group
          { id: 5, path: "0/", author_id: 200, target_id: 0, target_type: 'Issue', action: 1, created_at: from + 2.days,
            updated_at: from + 2.days }
        ])
      end

      it 'returns distinct contributor count from ClickHouse' do
        expect(service_response).to be_success
        expect(service_response.payload[:count]).to eq(2)
      end
    end
  end
end
