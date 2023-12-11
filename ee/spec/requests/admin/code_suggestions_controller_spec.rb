# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CodeSuggestionsController, :cloud_licenses, feature_category: :seat_cost_management do
  include AdminModeHelper

  describe 'GET /code_suggestions' do
    before do
      allow(::Gitlab::Saas).to receive(:feature_available?).and_return(false)
    end

    shared_examples 'renders the activation form' do
      it 'renders the activation form' do
        get admin_code_suggestions_path

        expect(response).to render_template(:index)
        expect(response.body).to include('js-code-suggestions-page')
      end
    end

    shared_examples 'hides code suggestions path' do
      it 'returns 404' do
        get admin_code_suggestions_path

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response).to render_template('errors/not_found')
      end
    end

    context 'when the user is not admin' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it_behaves_like 'hides code suggestions path'
    end

    context 'when the user is an admin' do
      let_it_be(:admin) { create(:admin) }

      before do
        login_as(admin)
        enable_admin_mode!(admin)
      end

      it_behaves_like 'renders the activation form'

      context 'when instance is self-managed' do
        before do
          stub_saas_features(gitlab_saas_subscriptions: false)
        end

        context 'when self_managed_code_suggestions feature flag is enabled' do
          before do
            stub_feature_flags(self_managed_code_suggestions: true)
          end

          it_behaves_like 'renders the activation form'
        end

        context 'when self_managed_code_suggestions feature flag is disabled' do
          before do
            stub_feature_flags(self_managed_code_suggestions: false)
          end

          it_behaves_like 'hides code suggestions path'
        end
      end

      context 'when instance is SaaS' do
        where(:self_managed_code_suggestions) do
          [true, false]
        end

        with_them do
          before do
            stub_saas_features(gitlab_saas_subscriptions: true)
            stub_feature_flags(self_managed_code_suggestions: self_managed_code_suggestions)
          end

          it_behaves_like 'hides code suggestions path'
        end
      end
    end
  end
end
