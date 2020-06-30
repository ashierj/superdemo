# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views issue designs', :js do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, issue: issue) }

  context 'design_management_moved flag disabled' do
    before do
      enable_design_management
      stub_feature_flags(design_management_moved: false)

      visit project_issue_path(project, issue)

      click_link 'Designs'
    end

    it 'opens design detail' do
      click_link design.filename

      page.within(find('.js-design-header')) do
        expect(page).to have_content(design.filename)
      end

      expect(page).to have_selector('.js-design-image')
    end
  end

  context 'design_management_moved flag enabled' do
    before do
      enable_design_management

      visit project_issue_path(project, issue)
    end

    it 'opens design detail' do
      click_link design.filename

      page.within(find('.js-design-header')) do
        expect(page).to have_content(design.filename)
      end

      expect(page).to have_selector('.js-design-image')
    end
  end
end
