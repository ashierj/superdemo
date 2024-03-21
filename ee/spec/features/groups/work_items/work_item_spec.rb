# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item', :js, feature_category: :team_planning do
  include ListboxHelpers

  let_it_be_with_reload(:user) { create(:user) }

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:work_item) { create(:work_item, :epic, :group_level, namespace: group) }
  let(:work_items_path) { group_work_item_path(group, work_item.iid) }

  context 'for signed in user' do
    before do
      group.add_developer(user) # rubocop:disable RSpec/BeforeAllRoleAssignment -- we can remove this when we have more ee features specs
      sign_in(user)
      visit work_items_path
    end

    it_behaves_like 'work items rolled up dates'
  end
end
