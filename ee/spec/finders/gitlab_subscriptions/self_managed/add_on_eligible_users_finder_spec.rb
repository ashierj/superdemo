# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::SelfManaged::AddOnEligibleUsersFinder, feature_category: :seat_cost_management do
  describe '#execute' do
    let(:code_suggestions_finder) { described_class.new(add_on_type: :code_suggestions) }

    let_it_be(:active_user) { create(:user) }
    let_it_be(:bot) { create(:user, :bot) }
    let_it_be(:ghost) { create(:user, :ghost) }
    let_it_be(:blocked_user) { create(:user, :blocked) }
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:pending_approval_user) { create(:user, :blocked_pending_approval) }
    let_it_be(:group) { create(:group) }
    let_it_be(:guest_user) { create(:group_member, :guest, source: group).user }

    it 'returns no users for non_code_suggestions add-on types' do
      non_code_suggestions_finder = described_class.new(add_on_type: :some_other_addon)
      expect(non_code_suggestions_finder.execute).to be_empty
    end

    it 'returns billable users for code_suggestions' do
      expect(code_suggestions_finder.execute).to include(active_user)
      expect(code_suggestions_finder.execute).not_to include(bot, ghost, blocked_user, banned_user,
        pending_approval_user)
    end

    it 'includes guest users for code_suggestions' do
      expect(code_suggestions_finder.execute).to include(guest_user)
    end

    it 'filters users by search term if provided' do
      matching_user = create(:user, name: 'Matching User')
      non_matching_user = create(:user, name: 'Non')

      finder_with_search_term = described_class.new(add_on_type: :code_suggestions, search_term: 'Matching')

      expect(finder_with_search_term.execute).to include(matching_user)
      expect(finder_with_search_term.execute).not_to include(non_matching_user)
    end
  end
end
