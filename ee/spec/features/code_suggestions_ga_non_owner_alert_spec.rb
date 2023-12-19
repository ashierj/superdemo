# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Code suggestions GA notify non-owner alert', :saas, :js, feature_category: :code_suggestions do
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
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
    stub_feature_flags(code_suggestions_ga_non_owner_alert: false)
    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  context 'when primary CTA button clicked' do
    it 'is dismissed and remains dismissed' do
      visit group_path(group)

      expect(page).to have_link('Learn more',
        href: help_page_path('user/project/repository/code_suggestions/saas', anchor: 'use-code-suggestions'))

      click_on 'Learn more'

      wait_for_requests

      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
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
    find('button[data-testid="hide-code-suggestions-ga-non-owner-alert"]')
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
    expect(page).to have_text 'Try GitLab Duo Code Suggestions today'
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text 'Try GitLab Duo Code Suggestions today'
  end
end
