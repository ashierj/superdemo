# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group show page', :js, :saas, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private).tap { |g| g.add_owner(user) } }

  let(:path) { group_path(group) }

  context "with free tier badge" do
    let(:tier_badge_element) { find_by_testid('tier-badge') }
    let(:popover_element) { page.find('.gl-popover') }

    before do
      sign_in(user)
      visit path
    end

    it 'renders the tier badge and popover when clicked' do
      expect(tier_badge_element).to be_present

      tier_badge_element.click

      expect(popover_element.text).to include('Enhance team productivity')
      expect(popover_element.text).to include('This group and all its related projects use the Free GitLab tier.')
    end
  end
end
