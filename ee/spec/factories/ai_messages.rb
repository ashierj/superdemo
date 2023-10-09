# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :ai_chat_message, class: 'Gitlab::Llm::ChatMessage' do
    id { nil }
    association :user
    resource { nil }
    role { 'user' }
    request_id { SecureRandom.uuid }
    content { 'user message' }
    timestamp { Time.current }
    extras { nil }
    errors { nil }
    ai_action { 'chat' }
    client_subscription_id { nil }
    type { nil }
    chunk_id { nil }

    initialize_with do
      new(
        id: id,
        role: role,
        user: user,
        request_id: request_id,
        content: content,
        timestamp: timestamp,
        extras: extras,
        errors: errors,
        ai_action: ai_action,
        client_subscription_id: client_subscription_id,
        resource: resource,
        type: type,
        chunk_id: chunk_id
      )
    end
  end
end
