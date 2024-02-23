# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ComplianceFrameworksController, feature_category: :compliance_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:framework) { create(:compliance_framework, namespace: group) }

  before do
    stub_licensed_features(compliance_framework: true, custom_compliance_frameworks: true)

    login_as(user)
  end

  describe 'POST #create' do
    let(:params) { { framework: framework.id } }

    context 'when user has permissions to update the framework' do
      before_all do
        project.add_owner(user)
      end

      it 'redirects with notice message' do
        post project_compliance_frameworks_path(project), params: params

        expect(response).to redirect_to(edit_project_path(project, anchor: 'js-general-project-settings'))
        expect(flash[:notice]).to eq("Project '#{project.name}' was successfully updated.")
      end
    end

    context 'when user does not have permissions to update the framework' do
      it 'returns a 404' do
        post project_compliance_frameworks_path(project), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
