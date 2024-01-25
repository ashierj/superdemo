# frozen_string_literal: true

FactoryBot.define do
  factory :github_integration, class: 'Integrations::Github' do
    project
    type { 'Integrations::Github' }
    active { true }
    token { 'github-token' }
    repository_url { 'https://github.com/owner/repository' }
  end

  factory :git_guardian_integration, class: 'Integrations::GitGuardian' do
    project
    type { 'Integrations::GitGuardian' }
    active { true }
    token { 'git_guardian-token' }
  end
end
