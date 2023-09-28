# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :ai_chat_message, class: 'Gitlab::Llm::ChatMessage' do
    association :user
    id { nil }
    role { 'user' }
    request_id { SecureRandom.uuid }
    content { 'user message' }
    timestamp { Time.current }
    extras { nil }
    errors { nil }

    initialize_with do
      new(
        id: id,
        role: role,
        request_id: request_id,
        content: content,
        timestamp: timestamp,
        extras: extras,
        errors: errors
      )
    end
  end
end
