# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationController do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :repository, namespace: group) }

  before do
    stub_licensed_features(security_dashboard: true)
    group.add_developer(user)
  end

  describe 'POST #auto_fix', feature_category: :software_composition_analysis do
    subject(:request) { post :auto_fix, params: params }

    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        feature: feature,
        enabled: false
      }
    end

    before do
      project.add_maintainer(maintainer)
      project.add_developer(developer)
      sign_in(user)
    end

    context 'with feature enabled' do
      let(:feature) { :dependency_scanning }

      before do
        request
      end

      context 'with sufficient permissions' do
        let(:user) { maintainer }

        context 'with setup feature param' do
          let(:feature) { :dependency_scanning }

          it 'processes request and updates setting' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(project.security_setting.reload.auto_fix_dependency_scanning).to be_falsey
            expect(json_response['dependency_scanning']).to be(false)
          end
        end

        context 'without setup feature param' do
          let(:feature) { '' }

          it 'processes request and updates setting' do
            setting = project.reload.security_setting

            expect(response).to have_gitlab_http_status(:ok)
            expect(setting.auto_fix_dependency_scanning).to be_falsey
            expect(setting.auto_fix_dast).to be_falsey
            expect(json_response['dependency_scanning']).to be(false)
            expect(json_response['container_scanning']).to be(false)
          end
        end

        context 'without processable feature' do
          let(:feature) { :dep_scan }

          it 'does not pass validation' do
            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(project.security_setting.auto_fix_dependency_scanning).to be_truthy
          end
        end
      end

      context 'without sufficient permissions' do
        let(:user) { developer }
        let(:feature) { '' }

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end
    end

    context 'with feature disabled' do
      let(:user) { maintainer }
      let(:feature) { :dependency_scanning }

      before do
        stub_feature_flags(security_auto_fix: false)

        request
      end

      it { expect(response).to have_gitlab_http_status(:not_found) }
    end
  end
end
