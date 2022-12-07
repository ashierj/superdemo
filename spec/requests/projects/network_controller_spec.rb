# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::NetworkController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, :private) }
  let(:ref) { 'master' }

  describe 'GET #show' do
    subject { get project_network_path(project, ref) }

    context 'when user is unauthorized' do
      it 'shows 404' do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authorized' do
      let(:user) { project.creator }

      before do
        sign_in(user)
      end

      it 'renders content' do
        subject
        expect(response).to be_successful
      end

      context 'when ref_type is provided' do
        subject { get project_network_path(project, ref, ref_type: 'heads') }

        it 'assigns url with ref_type' do
          subject
          expect(assigns(:url)).to eq(project_network_path(project, ref, format: :json, ref_type: 'heads'))
        end

        context 'when the use_ref_type_parameter flag is disabled' do
          before do
            stub_feature_flags(use_ref_type_parameter: false)
          end

          it 'assigns url without ref_type' do
            subject
            expect(assigns(:url)).to eq(project_network_path(project, ref, format: :json))
          end
        end
      end

      it 'assigns url' do
        subject
        expect(assigns(:url)).to eq(project_network_path(project, ref, format: :json))
      end
    end
  end
end
