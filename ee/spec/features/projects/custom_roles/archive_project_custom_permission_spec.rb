# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Archive Project Custom Permission', feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :in_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:custom_role) { create(:member_role, :guest, namespace: project.root_namespace, archive_project: true) }

  before do
    stub_licensed_features(custom_roles: true)
    create(:project_member, :guest, member_role: custom_role, user: user, project: project)
    sign_in(user)
  end

  context 'when the project is not archived', :js, :aggregate_failures do
    it 'allows a guest user with custom `archive_project` permissions to archive it' do
      visit project_path(project)

      within_testid('super-sidebar') do
        click_button('Settings')
        click_link('General')
      end

      click_link('Archive project')
      click_button('Archive project')

      expect(page).to have_current_path(project_path(project))
      expect(project.reload.archived?).to eq(true)
    end
  end

  context 'when the project is archived', :js, :aggregate_failures do
    let_it_be(:project) { create(:project, :archived, namespace: project.namespace) }

    it 'allows a guest user with custom `archive_project` permissions to unarchive it' do
      visit project_path(project)

      within_testid('super-sidebar') do
        click_button('Settings')
        click_link('General')
      end

      click_link('Unarchive project')
      click_button('Unarchive project')

      expect(page).to have_current_path(project_path(project))
      expect(project.reload).not_to be_archived
    end
  end

  shared_examples 'does not allow the user to archive the project' do
    it 'does not show the `Settings` sidebar item', :js do
      visit project_path(project)

      within_testid('super-sidebar') do
        expect(page).not_to have_button('Settings')
      end
    end

    it 'does not allow access to the edit page' do
      visit edit_project_path(project)

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when the `custom_roles` licensed feature is not available' do
    before do
      stub_licensed_features(custom_roles: false)
    end

    it_behaves_like 'does not allow the user to archive the project'
  end

  context 'when the user does not have the custom `archive_project` permission' do
    let_it_be(:custom_role) { create(:member_role, :guest, namespace: project.root_namespace, archive_project: false) }

    it_behaves_like 'does not allow the user to archive the project'
  end
end
