# frozen_string_literal: true

FactoryBot.define do
  factory :github_integration, class: 'Integrations::Github' do
    project
    type { 'Integrations::Github' }
    active { true }
    token { 'github-token' }
    repository_url { 'https://github.com/owner/repository' }
  end

  factory :google_cloud_platform_artifact_registry_integration,
    class: 'Integrations::GoogleCloudPlatform::ArtifactRegistry' do
    project
    type { 'Integrations::GoogleCloudPlatform::ArtifactRegistry' }
    active { true }
    workload_identity_pool_project_number { '917659427920' }
    workload_identity_pool_id { 'gitlab-gcp-demo' }
    workload_identity_pool_provider_id { 'gitlab-gcp-prod-gitlab-org' }
    artifact_registry_project_id { 'dev-gcp-9abafed1' }
    artifact_registry_location { 'us-east1' }
    artifact_registry_repositories { 'demo, my-repo' }
  end

  factory :git_guardian_integration, class: 'Integrations::GitGuardian' do
    project
    type { 'Integrations::GitGuardian' }
    active { true }
    token { 'git_guardian-token' }
  end
end
