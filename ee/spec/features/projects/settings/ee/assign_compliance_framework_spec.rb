# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Assign compliance framework', feature_category: :compliance_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:framework) { create(:compliance_framework, namespace: project.group) }

  shared_examples 'assigning a compliance framework' do
    before_all do
      group.add_owner(user)
    end

    before do
      stub_licensed_features(compliance_framework: true, custom_compliance_frameworks: true)

      sign_in(user)
    end

    it 'assigns a compliance framework' do
      visit edit_project_path(project)

      page.within('.compliance-framework') do
        framework_select = find('select')
        framework_select.select(framework.name)

        click_button 'Save changes'
        wait_for_requests

        expect(page).to have_content(framework.name)
      end

      expect(page).to have_content("'#{project.name}' was successfully updated.")
    end
  end

  context 'with assign_compliance_project_service feature enabled' do
    before do
      stub_feature_flags(assign_compliance_project_service: true)
    end

    it_behaves_like 'assigning a compliance framework'
  end

  context 'with assign_compliance_project_service feature disabled' do
    before do
      stub_feature_flags(assign_compliance_project_service: false)
    end

    it_behaves_like 'assigning a compliance framework'
  end
end
