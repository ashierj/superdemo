# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Compliance framework', :js, feature_category: :compliance_management do
  let_it_be(:admin_user) { create(:user, admin: true) }
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, :repository, group: group) }
  let_it_be(:project_2) { create(:project, :repository, group: group) }
  let_it_be(:project_3) { create(:project, :repository, group: sub_group) }
  let_it_be(:compliance_framework_a) { create(:compliance_framework, namespace: group, name: 'FrameworkA') }
  let_it_be(:compliance_framework_b) { create(:compliance_framework, namespace: group, name: 'FrameworkB') }
  let_it_be(:framework_settings_first) do
    create(:compliance_framework_project_setting, project: project_1,
      compliance_management_framework: compliance_framework_a)
  end

  let_it_be(:framework_settings_second) do
    create(:compliance_framework_project_setting, project: project_3,
      compliance_management_framework: compliance_framework_b)
  end

  let(:default_framework_element) { find_by_testid('compliance-framework-default-label') }
  let(:framework_element) { find_by_testid('compliance-framework-label') }
  let(:associated_project_selector) { 'td[data-label="Associated projects"]' }

  before_all do
    group.add_owner(admin_user)
    sign_in(admin_user)
  end

  context 'with top level group and subgroup' do
    context 'with compliance dashboard feature enabled' do
      before do
        group.namespace_settings.update!(default_compliance_framework_id: compliance_framework_a.id)
        stub_licensed_features(group_level_compliance_dashboard: true)
      end

      it 'shows frameworks with associated projects in compliance center' do
        visit group_security_compliance_framework_reports_path(group)
        wait_for_requests
        expect(default_framework_element).to have_content(compliance_framework_a.name)

        expect(default_framework_element.find(:xpath, "../../../../..")
                                        .find(associated_project_selector).text).to eq(project_1.name)

        expect(framework_element).to have_content(compliance_framework_b.name)

        expect(framework_element.find(:xpath, "../../../../..")
                                .find(associated_project_selector).text).to eq(project_3.name)

        expect(page).not_to have_content(project_2.name)
      end
    end

    context 'with compliance dashboard feature disabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: false)
      end

      it 'renders 404 for compliance center path' do
        visit group_security_compliance_framework_reports_path(group)
        expect(page).to have_content('Not Found')
      end
    end
  end
end
