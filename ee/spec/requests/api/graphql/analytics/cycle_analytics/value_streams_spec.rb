# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '(Project|Group).value_streams', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:variables) { { fullPath: resource.full_path } }

  let(:query) do
    <<~QUERY
      query($fullPath: ID!, $valueStreamId: ID, $stageId: ID) {
        #{resource_type}(fullPath: $fullPath) {
          valueStreams(id: $valueStreamId) {
            nodes {
              name
              stages(id: $stageId) {
                name
                endEventHtmlDescription
                startEventHtmlDescription
                startEventLabel {
                  title
                }
                endEventLabel {
                  title
                }
              }
            }
          }
        }
      }
    QUERY
  end

  shared_examples 'value streams query' do
    context 'when value streams are licensed' do
      let_it_be(:value_streams) do
        [
          create(
            :cycle_analytics_value_stream,
            namespace: namespace,
            name: 'Custom 1'
          ),
          create(
            :cycle_analytics_value_stream,
            namespace: namespace,
            name: 'Custom 2'
          )
        ]
      end

      before do
        stub_licensed_features(
          cycle_analytics_for_projects: true,
          cycle_analytics_for_groups: true
        )
      end

      context 'when current user has permissions' do
        before_all do
          resource.add_reporter(current_user)
        end

        it 'returns custom value streams' do
          post_graphql(query, current_user: current_user, variables: variables)

          expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes)).to have_attributes(size: 2)
          expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 0, :name)).to eq('Custom 1')
          expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 1, :name)).to eq('Custom 2')
        end

        context 'when specifying the value stream id argument' do
          let(:value_stream) { value_streams.last }
          let(:variables) { { fullPath: resource.full_path, valueStreamId: value_stream.to_gid.to_s } }

          before do
            post_graphql(query, current_user: current_user, variables: variables)
          end

          it 'returns only one value stream' do
            expect(graphql_data_at(resource_type.to_sym, :value_streams,
              :nodes)).to match([hash_including('name' => 'Custom 2')])
          end

          context 'when value stream id outside of the group is given' do
            let(:value_stream) { create(:cycle_analytics_value_stream, name: 'outside') }

            it 'returns no data error' do
              expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes)).to be_empty
            end
          end
        end

        context 'when value stream has stages' do
          def perform_request
            post_graphql(query, current_user: current_user, variables: variables)
          end

          context 'with associated labels' do
            let_it_be(:stage_with_label) do
              create(:cycle_analytics_stage, {
                name: 'stage-with-label',
                namespace: namespace,
                value_stream: value_streams[0],
                start_event_identifier: :issue_label_added,
                start_event_label_id: start_label.id,
                end_event_identifier: :issue_label_removed,
                end_event_label_id: end_label.id
              })
            end

            it 'returns label event attributes' do
              perform_request

              expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 0, :stages, 0, :start_event_label,
                :title)).to eq('Start Label')
              expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 0, :stages, 0, :end_event_label,
                :title)).to eq('End Label')
            end

            it 'renders the html descriptions' do
              perform_request

              expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 0, :stages, 0)).to match(
                hash_including(
                  'startEventHtmlDescription' => include("#{start_label.title}</span>"),
                  'endEventHtmlDescription' => include("#{end_label.title}</span>")
                )
              )
            end
          end

          it 'prevents n+1 queries' do
            perform_request # warmup
            create(:cycle_analytics_stage, value_stream: value_streams[0], namespace: namespace, name: 'Test')
            control = ActiveRecord::QueryRecorder.new { perform_request }
            value_stream_3 = create(
              :cycle_analytics_value_stream,
              namespace: namespace,
              name: 'Custom 3'
            )
            create(:cycle_analytics_stage, value_stream: value_stream_3, namespace: namespace, name: 'Code')

            expect { perform_request }.to issue_same_number_of_queries_as(control)
          end

          context 'when specifying the stage id argument' do
            let(:value_stream) { value_streams.first }
            let!(:stage) { create(:cycle_analytics_stage, value_stream: value_stream, namespace: namespace) }

            let(:variables) do
              {
                fullPath: resource.full_path,
                valueStreamId: value_stream.to_gid.to_s,
                stageId: stage.to_gid.to_s
              }
            end

            before do
              # should not show up in the results
              create(:cycle_analytics_stage, value_stream: value_stream, namespace: namespace)
            end

            it 'returns the queried stage' do
              perform_request

              expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 0, :stages)).to match([
                hash_including('name' => stage.name)
              ])
            end

            context 'when passing bogus stage id' do
              before do
                variables[:stageId] = create(:cycle_analytics_stage).to_gid.to_s
              end

              it 'returns no stages' do
                perform_request

                expect(graphql_data_at(resource_type.to_sym, :value_streams, :nodes, 0, :stages)).to be_empty
              end
            end
          end
        end
      end
    end
  end

  context 'for projects' do
    let(:resource_type) { 'project' }

    let_it_be(:resource) { create(:project, group: create(:group)) }
    let_it_be(:namespace) { resource.project_namespace }
    let_it_be(:start_label) { create(:label, project: resource, title: 'Start Label') }
    let_it_be(:end_label) { create(:label, project: resource, title: 'End Label') }

    it_behaves_like 'value streams query'

    context 'when value streams are not licensed' do
      before_all do
        resource.add_reporter(current_user)
      end

      it 'returns default value stream' do
        post_graphql(query, current_user: current_user, variables: variables)

        expect(graphql_data_at(:project, :value_streams, :nodes, 0, :name)).to eq('default')
        expect(graphql_data_at(:project, :value_streams)).to have_attributes(size: 1)
      end
    end
  end

  context 'for groups' do
    let(:resource_type) { 'group' }

    let_it_be(:resource) { create(:group) }
    let_it_be(:namespace) { resource }
    let_it_be(:start_label) { create(:group_label, group: resource, title: 'Start Label') }
    let_it_be(:end_label) { create(:group_label, group: resource, title: 'End Label') }

    it_behaves_like 'value streams query'

    context 'when current user does not have permissions' do
      it 'does not return value streams' do
        post_graphql(query, current_user: current_user, variables: variables)

        expect(graphql_data_at(:group, :value_streams)).to be_nil
      end
    end
  end
end
