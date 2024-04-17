# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Duo Chat GA alert', :saas, :js, feature_category: :duo_chat do
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user_in_group) { create(:group_member, :guest, user: create(:user), group: group).user }

  before do
    stub_feature_flags(duo_chat_ga_alert: true)
    sign_in(user_in_group)
  end

  it 'passes axe automated accessibility testing' do
    visit group_path(group)

    wait_for_requests

    expect(page).to be_axe_clean.within('[data-testid="duo-chat-ga-alert"]') # rubocop:todo Capybara/TestidFinders -- Doesn't cover use case, see https://gitlab.com/gitlab-org/gitlab/-/issues/442224
  end

  context 'with Duo Chat features enabled' do
    include_context 'with ai features enabled for group'
    context 'when primary CTA button clicked' do
      it 'opens Duo Chat drawer' do
        visit group_path(group)

        wait_for_all_requests

        click_on 'Use GitLab Duo Chat'

        expect(page).to have_selector '[data-testid="chat-component"]'
      end

      it 'dismisses the alert permanently' do
        visit group_path(group)
        click_on 'Use GitLab Duo Chat'

        wait_for_all_requests

        expect_banner_to_be_absent

        visit group_path(group)

        expect_group_page_for(group)
        expect_banner_to_be_absent
      end
    end

    it 'does not show the Duo Chat callout popover' do
      visit group_path(group)

      wait_for_all_requests

      expect_banner_to_be_present

      expect_popover_to_be_absent
    end
  end

  context 'when dismiss button clicked' do
    it 'is dismissed permanently' do
      visit group_path(group)
      dismiss_button.click

      wait_for_all_requests

      expect_banner_to_be_absent

      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end
  end

  def dismiss_button
    find('button[data-testid="hide-duo-chat-ga-alert"]')
  end

  def expect_group_page_for(group)
    expect(page).to have_text group.name
    expect(page).to have_text "Group ID: #{group.id}"
  end

  def expect_banner_to_be_present
    expect(page).to have_text 'GitLab Duo Chat is generally available today'
    expect(page).to have_text 'Access a broad range of GitLab Duo features with your personal chat assistant'

    expect(page).to have_link('Access Chat in the IDE',
      href: help_page_path('user/gitlab_duo_chat', anchor: 'use-gitlab-duo-chat-in-the-web-ide'))
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text 'GitLab Duo Chat is generally available today'
    expect(page).not_to have_text 'Access a broad range of GitLab Duo features with your personal chat assistant'
  end

  def expect_popover_to_be_absent
    expect(page).not_to have_selector '[data-testid="duo-chat-promo-callout-popover"]'
  end
end
