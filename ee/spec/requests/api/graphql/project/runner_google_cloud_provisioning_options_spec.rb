# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'runnerGoogleCloudProvisioningOptions', feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be_with_refind(:project) { create(:project) }
  let_it_be_with_refind(:integration) { create(:google_cloud_platform_artifact_registry_integration, project: project) }
  let_it_be(:maintainer) { create(:user).tap { |user| project.add_maintainer(user) } }

  let(:client_klass) { GoogleCloudPlatform::Compute::Client }
  let(:current_user) { maintainer }
  let(:google_cloud_project_id) { 'project_id_override' }
  let(:expected_compute_client_args) do
    {
      project: project,
      user: current_user,
      gcp_project_id: google_cloud_project_id,
      gcp_wlif: integration.wlif
    }
  end

  let(:current_page_token) { nil }
  let(:expected_next_page_token) { nil }
  let(:node_name) { :regions }
  let(:item_type) { 'CiRunnerCloudProvisioningRegion' }
  let(:base_item_query_args) { {} }
  let(:item_query_args) { {} }
  let(:query) do
    graphql_query_for(
      :project, { fullPath: project.full_path },
      query_graphql_field(
        :runner_cloud_provisioning_options, { provider: :GOOGLE_CLOUD, cloud_project_id: google_cloud_project_id },
        "... on CiRunnerGoogleCloudProvisioningOptions {
          #{query_nodes(
            node_name,
            args: base_item_query_args.merge(item_query_args),
            of: item_type,
            include_pagination_info: true)}
        }"
      )
    )
  end

  let(:options_response) do
    request
    graphql_data_at('project', 'runnerCloudProvisioningOptions')
  end

  subject(:request) do
    post_graphql(query, current_user: current_user)
  end

  before do
    stub_saas_features(google_cloud_support: true)
  end

  shared_examples 'a query handling client errors' do
    shared_examples 'returns error when client raises' do |error_klass, message|
      it "returns error when client raises #{error_klass}" do
        expect_next_instance_of(GoogleCloudPlatform::Compute::Client, expected_compute_client_args) do |client|
          expect(client).to receive(client_method).and_raise(error_klass, message)
        end

        post_graphql(query, current_user: current_user)
        expect_graphql_errors_to_include(message)
      end
    end

    it_behaves_like 'returns error when client raises', GoogleCloudPlatform::ApiError, 'api error'
    it_behaves_like 'returns error when client raises',
      GoogleCloudPlatform::AuthenticationError, 'Unable to authenticate against Google Cloud'
  end

  shared_examples 'a query calling compute client' do
    let(:page_size) { GoogleCloudPlatform::Compute::BaseService::MAX_RESULTS_LIMIT }
    let(:expected_client_args) { {} }
    let(:expected_pagination_client_args) { { max_results: page_size, page_token: current_page_token, order_by: nil } }
    let(:actual_returned_nodes) { returned_nodes }

    before do
      allow_next_instance_of(client_klass, expected_compute_client_args) do |client|
        allow(client).to receive(client_method)
          .with(a_hash_including(**expected_pagination_client_args.merge(expected_client_args))) do
            compute_type = client_method.to_s.camelize.singularize
            google_cloud_object_list(compute_type, actual_returned_nodes, next_page_token: expected_next_page_token)
          end
      end

      request
    end

    shared_examples 'a client returning paginated response' do
      it 'returns paginated response with items from client' do
        graphql_field_name = GraphqlHelpers.fieldnamerize(client_method)

        expect(options_response[graphql_field_name]).to match({
          'nodes' => expected_nodes.map { |node_props| a_graphql_entity_for(nil, **node_props) },
          'pageInfo' => a_hash_including(
            'hasPreviousPage' => !!current_page_token,
            'hasNextPage' => !!expected_next_page_token,
            'endCursor' => expected_next_page_token
          )
        })
      end
    end

    it_behaves_like 'a working graphql query'
    it_behaves_like 'a client returning paginated response'

    context 'with arguments' do
      let(:current_page_token) { 'prev_page_token' }
      let(:page_size) { 10 }
      let(:base_item_query_args) do
        { after: current_page_token, first: page_size }
      end

      it_behaves_like 'a client returning paginated response'

      context 'with pagination arguments requesting next page' do
        let(:current_page_token) { 'next_page_token' }
        let(:expected_next_page_token) { 'next_page_token2' }
        let(:page_size) { 1 }
        let(:expected_nodes) { returned_nodes[1..] }
        let(:actual_returned_nodes) { returned_nodes[1..] }
        let(:base_item_query_args) { { after: current_page_token, first: page_size } }

        it_behaves_like 'a client returning paginated response'
      end
    end
  end

  describe 'regions' do
    let(:item_type) { 'CiRunnerCloudProvisioningRegion' }
    let(:client_method) { :regions }
    let(:node_name) { :regions }
    let(:regions) do
      [
        { name: 'us-east1', description: 'us-east1' },
        { name: 'us-west1', description: 'us-west1' }
      ]
    end

    let(:returned_nodes) { regions }
    let(:expected_nodes) { returned_nodes }
    let(:expected_client_args) { { filter: nil } }

    it_behaves_like 'a query handling client errors'
    it_behaves_like 'a query calling compute client'
  end

  describe 'zones' do
    let(:item_type) { 'CiRunnerCloudProvisioningZone' }
    let(:client_method) { :zones }
    let(:node_name) { :zones }
    let(:zones) do
      [
        { name: 'us-east1-a', description: 'us-east1-a' },
        { name: 'us-west1-a', description: 'us-west1-a' }
      ]
    end

    let(:returned_nodes) { zones }
    let(:expected_nodes) { returned_nodes }
    let(:expected_client_args) { { filter: nil } }

    it_behaves_like 'a query handling client errors'
    it_behaves_like 'a query calling compute client'

    context 'with specified region' do
      let(:region) { 'us-east1' }
      let(:item_query_args) { { region: region } }
      let(:returned_nodes) { zones.select { |z| z[:name].starts_with?(region) } }
      let(:expected_next_page_token) { 'next_page_token' }

      it_behaves_like 'a query calling compute client' do
        let(:expected_client_args) { { filter: "name=#{region}-*" } }
      end
    end
  end

  describe 'machineTypes' do
    let(:item_type) { 'CiRunnerCloudProvisioningMachineType' }
    let(:client_method) { :machine_types }
    let(:node_name) { :machine_types }
    let(:machine_types) do
      [
        { zone: zone, name: 'e2-highcpu-8', description: 'Efficient Instance, 8 vCPUs, 8 GB RAM' },
        { zone: zone, name: 'e2-highcpu-16', description: 'Efficient Instance, 16 vCPUs, 16 GB RAM' }
      ]
    end

    let(:zone) { 'us-east1-a' }
    let(:item_query_args) { { zone: zone } }
    let(:returned_nodes) { machine_types }
    let(:expected_nodes) { returned_nodes }
    let(:expected_client_args) { { filter: "name=#{zone}-*" } }

    it_behaves_like 'a query handling client errors'
    it_behaves_like 'a query calling compute client'
  end

  context 'when user does not have required permissions' do
    let(:current_user) { create(:user).tap { |user| project.add_developer(user) } }

    it { is_expected.to be nil }
  end

  context 'when SaaS feature is not enabled' do
    before do
      stub_saas_features(google_cloud_support: false)
    end

    it { is_expected.to be nil }
  end

  context 'when google_cloud_runner_provisioning FF is disabled' do
    before do
      stub_feature_flags(google_cloud_runner_provisioning: false)
    end

    it { is_expected.to be nil }
  end

  context 'when integration is not present' do
    before do
      integration.destroy!
    end

    it 'returns error' do
      post_graphql(query, current_user: current_user)
      expect_graphql_errors_to_include(/integration not set/)
    end
  end

  context 'when integration is inactive' do
    before do
      integration.update_column(:active, false)
    end

    it 'returns error' do
      post_graphql(query, current_user: current_user)
      expect_graphql_errors_to_include(/integration not active/)
    end
  end

  private

  def google_cloud_object_list(compute_type, returned_nodes, next_page_token:)
    item_type = "Google::Cloud::Compute::V1::#{compute_type}"

    # rubocop:disable RSpec/VerifiedDoubles -- these generated objects don't actually expose the methods
    double("#{item_type}List",
      items: returned_nodes.map { |props| double(item_type, **props) },
      next_page_token: next_page_token
    )
    # rubocop:enable RSpec/VerifiedDoubles
  end
end
