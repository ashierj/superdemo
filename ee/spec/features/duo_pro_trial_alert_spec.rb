# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Duo Pro Trial alert', :saas, :js, feature_category: :code_suggestions do
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user_in_group) do
    create(:group_member, :owner, user: create(:user, namespace: create(:user_namespace)), group: group).user
  end

  let_it_be(:duo_pro_addon) { create(:gitlab_subscription_add_on, :gitlab_duo_pro) }

  before do
    sign_in(user_in_group)
  end

  context 'when dismiss button clicked' do
    it 'is dismissed' do
      visit group_path(group)
      dismiss_button.click

      wait_for_all_requests

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'remains dismissed' do
      visit group_path(group)
      dismiss_button.click

      wait_for_all_requests

      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end
  end

  def dismiss_button
    find('button[data-testid="hide-duo-pro-trial-alert"]')
  end

  def expect_group_page_for(group)
    expect(page).to have_text group.name
    expect(page).to have_text "Group ID: #{group.id}"
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text 'Try GitLab Duo Pro for free'
    expect(page).not_to have_text 'You can now try GitLab Duo Pro for free for 30 days, no credit card required.'
  end
end
