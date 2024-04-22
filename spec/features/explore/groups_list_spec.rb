# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Explore Groups page', :js, feature_category: :groups_and_projects do
  let!(:user) { create :user }
  let(:com?) { false }

  before do
    allow(Gitlab).to receive(:com?).and_return(com?)
  end

  context 'when there are groups to show' do
    let!(:group) { create(:group) }
    let!(:public_group) { create(:group, :public) }
    let!(:private_group) { create(:group, :private) }
    let!(:empty_project) { create(:project, group: public_group) }

    before do
      group.add_owner(user)

      sign_in(user)

      visit explore_groups_path
      wait_for_requests
    end

    it 'shows groups user is member of' do
      expect(page).to have_content(group.full_name)
      expect(page).to have_content(public_group.full_name)
      expect(page).not_to have_content(private_group.full_name)
    end

    it 'filters groups' do
      search(group.name)
      click_button 'Search'
      wait_for_requests

      expect(page).to have_content(group.full_name)
      expect(page).not_to have_content(public_group.full_name)
      expect(page).not_to have_content(private_group.full_name)
    end

    it 'resets search when user cleans the input' do
      search(group.name)
      click_button 'Search'
      wait_for_requests

      expect(page).to have_content(group.full_name)
      expect(page).not_to have_content(public_group.full_name)

      click_button 'Clear'
      wait_for_requests

      expect(page).to have_content(group.full_name)
      expect(page).to have_content(public_group.full_name)
      expect(page).not_to have_content(private_group.full_name)
      expect(page.all('[data-testid="groups-list-tree-container"] .groups-list li').length).to eq 2
    end

    it 'shows non-archived projects count' do
      # Initially project is not archived
      expect(
        find('[data-testid="groups-list-tree-container"] .groups-list li:first-child .stats .number-projects')
      ).to have_text("1")

      # Archive project
      ::Projects::UpdateService.new(empty_project, user, archived: true).execute
      visit explore_groups_path

      # Check project count
      expect(
        find('[data-testid="groups-list-tree-container"] .groups-list li:first-child .stats .number-projects')
      ).to have_text("0")

      # Unarchive project
      ::Projects::UpdateService.new(empty_project, user, archived: false).execute
      visit explore_groups_path

      # Check project count
      expect(
        find('[data-testid="groups-list-tree-container"] .groups-list li:first-child .stats .number-projects')
      ).to have_text("1")
    end

    context 'when on gitlab.com' do
      let(:com?) { true }

      it 'renders page description' do
        expect(page).to have_content(
          'Below you will find all the groups that are public. Contribute by requesting to join a group.'
        )
      end
    end

    context 'when on self-managed' do
      it 'renders page description' do
        expect(page).to have_content(
          'Below you will find all the groups that are public or internal. Contribute by requesting to join a group.'
        )
      end
    end
  end

  context 'when there are no groups to show' do
    before do
      sign_in(user)

      visit explore_groups_path
      wait_for_requests
    end

    context 'when on gitlab.com' do
      let(:com?) { true }

      it 'shows empty state' do
        expect(page).to have_content(_('No public groups'))
      end
    end

    context 'when on self-managed' do
      it 'shows empty state' do
        expect(page).to have_content(_('No public or internal groups'))
      end
    end
  end

  def search(term)
    filter_input = find_by_testid('filtered-search-term-input')
    filter_input.click
    filter_input.set(term)
    click_button 'Search'
  end
end
