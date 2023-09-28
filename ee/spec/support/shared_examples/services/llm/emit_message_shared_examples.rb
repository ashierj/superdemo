# frozen_string_literal: true

RSpec.shared_examples 'service emitting message for user prompt' do
  it 'triggers graphql subscription message' do
    allow(::Llm::CompletionWorker).to receive(:perform_async)

    expect(GraphqlTriggers).to receive(:ai_completion_response)
      .with({ user_id: user.to_global_id, resource_id: resource.to_global_id }, kind_of(Gitlab::Llm::AiMessage))

    expect(GraphqlTriggers).to receive(:ai_completion_response)
      .with({ user_id: user.to_global_id, ai_action: 'chat' }, kind_of(Gitlab::Llm::AiMessage))

    subject.execute
  end
end

RSpec.shared_examples 'service not emitting message for user prompt' do
  it 'does not trigger graphql subscription message' do
    allow(::Llm::CompletionWorker).to receive(:perform_async)

    expect(GraphqlTriggers).not_to receive(:ai_completion_response)

    subject.execute
  end
end
