# frozen_string_literal: true

FactoryBot.define do
  factory :ai_agent_version, class: '::Ai::AgentVersion' do
    agent { association :ai_agent }
    project { agent.project }
    prompt { 'Prompt text' }
    model { 'anthropic-claude-instant-1.1' }
  end
end
