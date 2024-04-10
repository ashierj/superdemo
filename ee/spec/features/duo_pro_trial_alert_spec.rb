# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Duo Pro Trial alert', :saas, :js, feature_category: :code_suggestions do
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user_in_group) do
    create(:group_member, :owner, user: create(:user, namespace: create(:user_namespace)), group: group).user
  end

  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:duo_pro_addon) { create(:gitlab_subscription_add_on, :gitlab_duo_pro) }

  before do
    stub_saas_features(subscriptions_trials: true)
    stub_feature_flags(duo_pro_trials: true)
    sign_in(user_in_group)
  end

  it 'displays the banner at the required pages' do
    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_present

    visit group_path(subgroup)

    expect_group_page_for(subgroup)
    expect_banner_to_be_present

    visit project_path(project)

    expect_project_page_for(project)
    expect_banner_to_be_present
  end

  it 'does not display the banner when the feature flag is off' do
    stub_feature_flags(duo_pro_trial_alert: false)
    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  context 'when primary CTA button clicked' do
    it 'navigates to duo pro trial page' do
      visit group_path(group)
      click_on 'Start trial now'

      wait_for_all_requests

      expect(page).to have_current_path(new_trials_duo_pro_path(namespace_id: group.id))
    end
  end

  context 'when dismiss button clicked' do
    it 'is dismissed' do
      visit group_path(group)
      dismiss_button.click

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'remains dismissed' do
      visit group_path(group)
      dismiss_button.click

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

  def expect_project_page_for(project)
    expect(page).to have_text project.namespace.name
    expect(page).to have_text project.name
  end

  def expect_banner_to_be_present
    expect(page).to have_text 'Try GitLab Duo Pro for free'
    expect(page).to have_text 'You can now try GitLab Duo Pro for free for 30 days, no credit card required.'

    expect(page).to have_link('Learn more about GitLab Duo Pro', href: help_page_path('user/ai_features'))
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text 'Try GitLab Duo Pro for free'
    expect(page).not_to have_text 'You can now try GitLab Duo Pro for free for 30 days, no credit card required.'
  end
end
