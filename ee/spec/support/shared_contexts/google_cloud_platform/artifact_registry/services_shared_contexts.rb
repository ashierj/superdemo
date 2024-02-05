# frozen_string_literal: true

RSpec.shared_context 'for an artifact registry service' do
  let_it_be_with_reload(:project) { create(:project, :private) }
  let_it_be_with_refind(:project_integration) do
    create(
      :google_cloud_platform_artifact_registry_integration,
      project: project,
      artifact_registry_project_id: 'gcp_project_id',
      artifact_registry_location: 'location',
      artifact_registry_repositories: 'repository1,repository2', # only repository1 is taken into account
      workload_identity_pool_project_number: '555',
      workload_identity_pool_id: 'my_pool',
      workload_identity_pool_provider_id: 'my_provider'
    )
  end

  let(:user) { project.owner }
  let(:params) { {} }
  let(:service) { described_class.new(project: project, current_user: user, params: params) }
  let(:client_double) { instance_double('::GoogleCloudPlatform::ArtifactRegistry::Client') }

  before do
    allow(::GoogleCloudPlatform::ArtifactRegistry::Client).to receive(:new)
      .with(
        project: project,
        user: user,
        gcp_project_id: project_integration.artifact_registry_project_id,
        gcp_location: project_integration.artifact_registry_location,
        gcp_repository: project_integration.artifact_registry_repository,
        gcp_wlif: project_integration.wlif
      ).and_return(client_double)
  end
end
