# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User with read_code custom role', feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :in_group) }
  let_it_be(:role) { create(:member_role, :guest, :read_code, namespace: project.group) }
  let_it_be(:member) { create(:group_member, :guest, member_role: role, user: user, source: project.group) }

  before do
    stub_licensed_features(custom_roles: true)
  end

  describe SearchController do
    before do
      sign_in(user)
    end

    describe '#show' do
      let(:source_code) do
        "Mailer.deliver(to: 'bob@example.com', from: 'us@example.com', subject: 'Important message', body: source.text)"
      end

      context 'with elasticsearch', :elastic, :sidekiq_inline do
        before do
          stub_ee_application_setting(
            elasticsearch_indexing: true,
            elasticsearch_search: true
          )
          project.repository.index_commits_and_blobs
          ensure_elasticsearch_index!
        end

        context 'when searching a group' do
          it 'allows access via a custom role' do
            get search_path, params: {
              group_id: project.group.id,
              scope: 'blobs',
              search: 'Mailer.deliver'
            }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).not_to include('We couldn&#39;t find any code results matching')
            expect(response.body).to include('/files/markdown/ruby-style-guide.md#L452')
            expect(response.body).to include(source_code)
          end
        end

        context 'when searching a project' do
          it 'allows access via a custom role' do
            get search_path, params: {
              project_id: project.id,
              search_code: true,
              scope: 'blobs',
              search: 'Mailer.deliver'
            }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).not_to include('We couldn&#39;t find any code results matching')
            expect(response.body).to include('/files/markdown/ruby-style-guide.md#L452')
            expect(response.body).to include(source_code)
          end
        end
      end

      context 'with Zoekt', :zoekt do
        before do
          zoekt_ensure_project_indexed!(project)
        end

        context 'when searching a group' do
          # To be completed with: https://gitlab.com/gitlab-org/gitlab/-/issues/389750
          pending 'allows access via a custom role' do
            get search_path, params: {
              group_id: project.group.id,
              scope: 'blobs',
              search: 'Mailer.deliver'
            }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).not_to include('We couldn&#39;t find any code results matching')
            expect(response.body).to include('/files/markdown/ruby-style-guide.md')
            expect(response.body).to include(source_code)
          end
        end

        context 'when searching a project' do
          it 'allows access via a custom role' do
            get search_path, params: {
              project_id: project.id,
              search_code: true,
              scope: 'blobs',
              search: 'Mailer.deliver'
            }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).not_to include('We couldn&#39;t find any code results matching')
            expect(response.body).to include('/files/markdown/ruby-style-guide.md')
            expect(response.body).to include(source_code)
          end
        end
      end
    end
  end
end
