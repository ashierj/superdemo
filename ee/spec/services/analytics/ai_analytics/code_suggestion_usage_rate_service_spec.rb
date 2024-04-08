# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::AiAnalytics::CodeSuggestionUsageRateService, feature_category: :value_stream_management do
  subject(:service_response) do
    described_class.new(
      current_user,
      namespace: container,
      from: from,
      to: to
    ).execute
  end

  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user_without_ai_usage) { create(:user) }
  let_it_be(:unmatched_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }

  let(:current_user) { user1 }
  let(:from) { Time.zone.now }
  let(:to) { Time.zone.now }

  before_all do
    group.add_developer(user1)
    subgroup.add_developer(user2)
    group.add_developer(user_without_ai_usage)
  end

  before do
    allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)
  end

  shared_examples 'common ai usage rate service' do
    context 'when the clickhouse is not available for analytics' do
      before do
        allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).with(container).and_return(false)
      end

      it 'returns service error' do
        expect(service_response).to be_error

        message = s_('AiAnalytics|the ClickHouse data store is not available')
        expect(service_response.message).to eq(message)
      end
    end

    context 'when the feature is available', :click_house, :freeze_time do
      let(:from) { 14.days.ago }
      let(:to) { 1.day.ago }
      let(:traversal_path) { "#{contributions_target.traversal_ids.join('/')}/" }

      context 'without data' do
        it 'returns 0' do
          expect(service_response).to be_success
          expect(service_response.payload).to eq(0)
        end
      end

      context 'with data' do
        def format(date)
          date.to_time.utc.to_f
        end

        before do
          usages_query = <<~SQL
          INSERT INTO code_suggestion_usages
          (user_id, event, timestamp)
          VALUES
          (#{user1.id}, 1, #{format(to - 3.days)}),
          (#{user1.id}, 1, #{format(to - 4.days)}),
          (#{user1.id}, 1, #{format(to + 1.day)}),
          (#{user1.id}, 1, #{format(from - 1.day)}),
          (#{user2.id}, 1, #{format(to - 2.days)}),
          (#{unmatched_user.id}, 1, #{format(to - 2.days)})
          SQL

          ClickHouse::Client.execute(usages_query, :main)

          code_contributions_query = <<~SQL
          INSERT INTO events
          (id, path, author_id, target_id, target_type, action, created_at, updated_at)
          VALUES
          (1,'#{traversal_path}',#{user1.id},0,'',5,#{format(to - 1.day)},#{format(to - 1.day)}),
          (2,'#{traversal_path}',#{user1.id},0,'',5,#{format(to - 2.days)},#{format(to - 2.days)}),
          (3,'#{traversal_path}',#{user2.id},0,'',5,#{format(to - 1.day)},#{format(to - 1.day)}),
          (4,'#{traversal_path}',#{user_without_ai_usage.id},0,'',5,#{format(to - 1.day)},#{format(to - 1.day)}),
          SQL

          ClickHouse::Client.execute(code_contributions_query, :main)
        end

        it 'returns percentage of matched code contributors who used AI' do
          expect(service_response).to be_success
          expect(service_response.payload).to be_within(0.0001).of(2 / 3.0)
        end
      end
    end
  end

  context 'for group' do
    let_it_be(:container) { group }
    let_it_be(:contributions_target) { subgroup }

    it_behaves_like 'common ai usage rate service'
  end

  context 'for project' do
    let_it_be(:container) { create(:project, group: subgroup).project_namespace }
    let_it_be(:contributions_target) { container.reload }

    it_behaves_like 'common ai usage rate service'
  end
end
