# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::DependenciesController, feature_category: :dependency_management do
  describe 'GET #index' do
    describe 'GET index.html' do
      subject { get explore_dependencies_path }

      context 'when dependency scanning is available' do
        before do
          stub_licensed_features(dependency_scanning: true)
        end

        context 'when user is admin', :enable_admin_mode do
          let_it_be(:user) { create(:user, :admin) }
          let_it_be(:organization) { create(:organization, :default) }

          before do
            sign_in(user)
          end

          include_examples 'returning response status', :ok

          context 'when the feature flag is disabled' do
            before do
              stub_feature_flags(explore_dependencies: false)
            end

            include_examples 'returning response status', :not_found
          end
        end

        context 'when user is not admin' do
          let_it_be(:user) { create(:user) }

          before do
            sign_in(user)
          end

          include_examples 'returning response status', :forbidden
        end

        context 'when a user is not logged in' do
          include_examples 'returning response status', :not_found
        end
      end

      context 'when dependency scanning is not available' do
        before do
          stub_licensed_features(dependency_scanning: false)
        end

        include_examples 'returning response status', :not_found

        context 'when user is admin', :enable_admin_mode do
          let_it_be(:user) { create(:user, :admin) }
          let_it_be(:organization) { create(:organization, :default) }

          before do
            sign_in(user)
          end

          include_examples 'returning response status', :forbidden
        end
      end
    end

    describe 'GET index.json', :enable_admin_mode do
      subject { get explore_dependencies_path, as: :json }

      context 'when dependency scanning is available' do
        before do
          stub_licensed_features(dependency_scanning: true)
        end

        context 'when user is admin', :enable_admin_mode do
          let_it_be(:user) { create(:user, :admin) }
          let_it_be(:organization) { create(:organization, :default) }
          let_it_be(:group) { create(:group, organization: organization) }
          let_it_be(:project) { create(:project, organization: organization, group: group) }

          before do
            sign_in(user)
          end

          it 'renders a JSON response' do
            bundler_occurrence = create(:sbom_occurrence, :mit, :bundler, project: project)

            get explore_dependencies_path, as: :json

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_limited_pagination_headers
            expect(json_response["dependencies"]).to match_array([
              {
                'name' => bundler_occurrence.name,
                'packager' => bundler_occurrence.packager,
                'version' => bundler_occurrence.version,
                'location' => bundler_occurrence.location.as_json
              }
            ])
          end

          it 'avoids N+1 database queries' do
            get explore_dependencies_path, as: :json # warmup

            create(:sbom_occurrence, project: project)

            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              get explore_dependencies_path, as: :json
            end

            create_list(:project, 3, organization: organization).each do |project|
              create(:sbom_occurrence, project: project)
            end

            expect do
              get explore_dependencies_path, as: :json
            end.not_to exceed_query_limit(control)
          end

          include_examples 'returning response status', :ok
        end

        context 'when user is not admin' do
          let_it_be(:user) { create(:user) }

          before do
            sign_in(user)
          end

          include_examples 'returning response status', :forbidden
        end

        context 'when a user is not logged in' do
          include_examples 'returning response status', :not_found
        end
      end

      context 'when dependency scanning is not available' do
        before do
          stub_licensed_features(dependency_scanning: false)
        end

        include_examples 'returning response status', :not_found

        context 'when user is admin', :enable_admin_mode do
          let_it_be(:user) { create(:user, :admin) }
          let_it_be(:organization) { create(:organization, :default) }

          before do
            sign_in(user)
          end

          include_examples 'returning response status', :forbidden
        end
      end
    end
  end
end
