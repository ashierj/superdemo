# frozen_string_literal: true

RSpec.shared_context 'for a compute service' do
  let_it_be_with_reload(:project) { create(:project, :private) }
  let_it_be_with_refind(:project_integration) do
    create(
      :google_cloud_platform_artifact_registry_integration,
      project: project,
      artifact_registry_project_id: 'cloud_project_id',
      workload_identity_pool_project_number: '555',
      workload_identity_pool_id: 'my_pool',
      workload_identity_pool_provider_id: 'my_provider'
    )
  end

  let(:user) { project.owner }
  let(:service) { described_class.new(project: project, current_user: user, params: params) }
  let(:client_double) { instance_double('::GoogleCloudPlatform::Compute::Client') }
  let(:google_cloud_project_id) { nil }

  before do
    allow(::GoogleCloudPlatform::Compute::Client).to receive(:new)
      .with(
        project_integration: project_integration,
        user: user,
        params: params.slice(:google_cloud_project_id)
      ).and_return(client_double)
  end
end
