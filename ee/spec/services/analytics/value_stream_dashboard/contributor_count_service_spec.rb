# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::ContributorCountService, feature_category: :value_stream_management do
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

  context 'when the clickhouse_data_collection feature flag is off' do
    before do
      stub_feature_flags(clickhouse_data_collection: false)
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
      stub_feature_flags(clickhouse_data_collection: group)
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
      stub_feature_flags(clickhouse_data_collection: group)
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
      stub_feature_flags(clickhouse_data_collection: group)
      stub_licensed_features(group_level_analytics_dashboard: true)
    end

    def format(date)
      date.to_time.utc.to_f
    end

    context 'when no data present' do
      it 'returns 0' do
        expect(service_response).to be_success
        expect(service_response[:count]).to eq(0)
      end
    end

    context 'when data present' do
      before do
        insert_query = <<~SQL
        INSERT INTO events
        (id, path, author_id, target_id, target_type, action, created_at, updated_at)
        VALUES
        -- push event
        -- push event same user
        -- issue creation event, different user
        -- issue creation event, outside of the date range
        -- issue creation event, for a different group
        (1,'#{group.id}/',100,0,'',5,#{format(from + 5.days)},#{format(from + 5.days)}),
        (2,'#{group.id}/',100,0,'',5,#{format(from + 8.days)},#{format(from + 8.days)}),
        (3,'#{group.id}/',200,0,'Issue',1,#{format(from + 9.days)},#{format(from + 9.days)}),
        (4,'#{group.id}/',200,0,'Issue',1,#{format(from + 5.years)},#{format(from + 5.years)}),
        (5,'0',200,0,'Issue',1,#{format(from + 2.days)},#{format(from + 2.days)})
        SQL

        ClickHouse::Client.execute(insert_query, :main)
      end

      it 'returns distinct contributor count from ClickHouse' do
        expect(service_response).to be_success
        expect(service_response.payload[:count]).to eq(2)
      end
    end
  end
end
