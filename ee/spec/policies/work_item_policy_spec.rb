# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItemPolicy, feature_category: :team_planning do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:group) { create(:group, :public).tap { |g| g.add_reporter(reporter) } }

  def permissions(user, work_item)
    described_class.new(user, work_item)
  end

  context 'when work item has a synced epic' do
    let_it_be_with_reload(:work_item) { create(:epic, :with_synced_work_item, group: group).work_item }

    it 'does not allow modifying issue' do
      expect(permissions(reporter, work_item)).to be_disallowed(
        :admin_work_item_link, :admin_work_item, :update_work_item, :set_work_item_metadata,
        :create_note, :award_emoji, :create_todo, :update_subscription, :create_requirement_test_report
      )
    end
  end
end
