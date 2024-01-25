# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Integrations, feature_category: :integrations do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) do
    create(:group).tap { |g| g.add_owner(user) }
  end

  let_it_be(:project, reload: true) do
    create(:project, creator_id: user.id, group: group)
  end

  %w[integrations services].each do |endpoint|
    describe 'GitGuardian Integration' do
      let(:integration_name) { 'git-guardian' }

      context 'when git_guardian_integration feature flag is disabled' do
        before do
          stub_feature_flags(git_guardian_integration: false)
        end

        it 'returns 400  for put request' do
          put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user), params: { token: 'api-token' }
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to eq("{\"message\":\"GitGuardian feature is disabled\"}")
        end

        it 'returns 400  for delete request' do
          delete api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user)
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to eq("{\"message\":\"GitGuardian feature is disabled\"}")
        end
      end
    end
  end
end
