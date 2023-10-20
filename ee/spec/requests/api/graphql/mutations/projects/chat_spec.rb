# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'AiAction for chat', :saas, feature_category: :shared do
  include GraphqlHelpers

  let_it_be_with_reload(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }
  let_it_be(:resource) { create(:issue, project: project) }

  let(:mutation) do
    params = { chat: { resource_id: resource&.to_gid, content: "summarize" } }

    graphql_mutation(:ai_action, params) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  before do
    group.add_developer(current_user)
  end

  include_context 'with ai features enabled for group'

  context 'when resource is nil' do
    let(:resource) { nil }

    it 'successfully performs a chat request' do
      expect(Llm::CompletionWorker).to receive(:perform_for).with(
        an_object_having_attributes(
          user: current_user,
          resource: resource,
          ai_action: :chat,
          content: "summarize"),
        hash_including(referer_url: nil)
      )

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when resource is an issue' do
    it 'successfully performs a request' do
      expect(Llm::CompletionWorker).to receive(:perform_for).with(
        an_object_having_attributes(
          user: current_user,
          resource: resource,
          ai_action: :chat,
          content: "summarize"),
        hash_including(referer_url: nil)
      )

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
    end
  end

  context 'when resource is a user' do
    let_it_be_with_reload(:resource) { current_user }

    it 'successfully performs a request' do
      expect(Llm::CompletionWorker).to receive(:perform_for).with(
        an_object_having_attributes(
          user: current_user,
          resource: resource,
          ai_action: :chat,
          content: "summarize"),
        hash_including(referer_url: nil)
      )

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
    end
  end

  context 'when ai_global_switch feature flag is disabled' do
    before do
      stub_feature_flags(ai_global_switch: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_for)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end
end
