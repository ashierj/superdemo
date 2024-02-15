# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ProjectClassProxy, feature_category: :global_search do
  subject { described_class.new(Project) }

  let(:query) { 'blob' }
  let(:options) { {} }
  let(:elastic_search) { subject.elastic_search(query, options: options) }
  let(:request) { Elasticsearch::Model::Searching::SearchRequest.new(Project, '*') }
  let(:response) do
    Elasticsearch::Model::Response::Response.new(Project, request)
  end

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe '#elastic_search' do
    describe 'query', :elastic_delete_by_query do
      it 'has the correct named queries' do
        elastic_search.response

        assert_named_queries(
          'project:match:search_terms',
          'doc:is_a:project',
          'project:archived:false'
        )
      end

      context 'when project_ids is set' do
        let(:options) { { project_ids: [create(:project).id] } }

        it 'has the correct named queries' do
          elastic_search.response

          assert_named_queries(
            'project:match:search_terms',
            'doc:is_a:project',
            'project:membership:id',
            'project:archived:false'
          )
        end

        context 'when group_ids is also set' do
          let_it_be(:group) { create(:group, :internal) }
          let_it_be(:project) { create(:project, :private, group: group) }
          let_it_be(:user) { create(:user) }
          let(:options) { { project_ids: [project.id], group_ids: [group.id], group_id: group.id, current_user: user } }

          context 'when the user belongs to the group' do
            before_all do
              group.add_developer(user)
            end

            it 'has the correct named queries' do
              elastic_search.response

              assert_named_queries('project:ancestry_filter:descendants')
            end
          end

          context 'when the user does not belong to the group' do
            it 'has the correct named queries' do
              elastic_search.response

              assert_named_queries('project:membership:id', without: ['project:ancestry_filter:descendants'])
            end
          end

          context 'when the feature flag has not been enabled' do
            before_all do
              stub_feature_flags(advanced_search_project_traversal_ids_query: false)
              group.add_developer(user)
            end

            it 'has the correct named queries' do
              elastic_search.response

              assert_named_queries('project:membership:id', without: ['project:ancestry_filter:descendants'])
            end
          end
        end
      end

      context 'when include_archived is set' do
        let(:options) { { include_archived: true } }

        it 'does not have a filter for archived' do
          elastic_search.response

          assert_named_queries(
            'project:match:search_terms',
            'doc:is_a:project'
          )
        end
      end
    end
  end
end
