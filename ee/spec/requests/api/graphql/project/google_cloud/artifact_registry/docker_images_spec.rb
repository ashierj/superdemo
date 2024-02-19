# frozen_string_literal: true

require 'spec_helper'
require 'google/cloud/artifact_registry/v1'

RSpec.describe 'getting the google cloud docker images linked to a project', :freeze_time, feature_category: :container_registry do
  include GraphqlHelpers
  include GoogleApi::CloudPlatformHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:project_integration) do
    create(:google_cloud_platform_artifact_registry_integration, project: project)
  end

  let_it_be(:artifact_registry_repository_url) do
    "https://console.cloud.google.com/artifacts/docker/#{project_integration.artifact_registry_project_id}/" \
      "#{project_integration.artifact_registry_location}/#{project_integration.artifact_registry_repository}"
  end

  let(:user) { project.first_owner }
  let(:image) { 'ruby' }
  let(:digest) { 'sha256:4ca5c21b' }
  let(:client_double) { instance_double('::GoogleCloudPlatform::ArtifactRegistry::Client') }
  let(:page_token) { nil }
  let(:order_by) { nil }
  let(:page_size) { nil }
  let(:default_page_size) { ::GoogleCloudPlatform::ArtifactRegistry::ListDockerImagesService::DEFAULT_PAGE_SIZE }
  let(:next_page_token) { 'next_page_token' }

  let(:docker_image) do
    Google::Cloud::ArtifactRegistry::V1::DockerImage.new(
      name: "projects/#{project_integration.artifact_registry_project_id}/" \
            "locations/#{project_integration.artifact_registry_location}/" \
            "repositories/#{project_integration.artifact_registry_repository}/" \
            "dockerImages/#{image}@#{digest}",
      uri: "us-east1-docker.pkg.dev/#{project_integration.artifact_registry_project_id}/demo/#{image}@#{digest}",
      tags: ['97c58898'],
      image_size_bytes: 304_121_628,
      media_type: 'application/vnd.docker.distribution.manifest.v2+json',
      build_time: Time.now,
      update_time: Time.now,
      upload_time: Time.now
    )
  end

  let(:fields) do
    <<~QUERY
      projectId,
      repository,
      artifactRegistryRepositoryUrl,
      #{query_graphql_field('artifacts', params, artifacts_fields)}
    QUERY
  end

  let(:artifacts_fields) do
    <<~QUERY
      nodes {
        #{query_graphql_fragment('google_cloud_artifact_registry_docker_image'.classify)}
      }
      pageInfo {
        hasNextPage,
        startCursor,
        endCursor
      }
    QUERY
  end

  let(:params) do
    {}
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('googleCloudArtifactRegistryRepository', {}, fields)
    )
  end

  let(:repository_response) do
    graphql_data_at(:project, :google_cloud_artifact_registry_repository)
  end

  subject(:request) { post_graphql(query, current_user: user) }

  before do
    stub_saas_features(google_cloud_support: true)

    allow(::GoogleCloudPlatform::ArtifactRegistry::Client).to receive(:new)
      .with(
        project_integration: project_integration,
        user: user,
        artifact_registry_location: project_integration.artifact_registry_location,
        artifact_registry_repository: project_integration.artifact_registry_repository
      ).and_return(client_double)

    allow(client_double).to receive(:docker_images)
      .with(page_token: page_token, page_size: page_size || default_page_size, order_by: order_by)
      .and_return(dummy_list_docker_images_response)
  end

  shared_examples 'returning the expected response' do |start_cursor: nil, end_cursor: nil|
    it 'returns the proper response' do
      request

      expect(repository_response).to eq({
        'projectId' => project_integration.artifact_registry_project_id,
        'repository' => project_integration.artifact_registry_repository,
        'artifactRegistryRepositoryUrl' => artifact_registry_repository_url,
        'artifacts' => {
          'nodes' => [{
            'name' => docker_image.name,
            'uri' => docker_image.uri,
            'tags' => docker_image.tags,
            'imageSizeBytes' => docker_image.image_size_bytes.to_s,
            'mediaType' => docker_image.media_type,
            'buildTime' => Time.now.iso8601,
            'updateTime' => Time.now.iso8601,
            'uploadTime' => Time.now.iso8601,
            'projectId' => project_integration.artifact_registry_project_id,
            'location' => project_integration.artifact_registry_location,
            'repository' => project_integration.artifact_registry_repository,
            'image' => image,
            'digest' => digest,
            'artifactRegistryImageUrl' => "https://#{docker_image.uri}"
          }],
          'pageInfo' => {
            'endCursor' => end_cursor,
            'hasNextPage' => true,
            'startCursor' => start_cursor
          }
        }
      })
    end
  end

  it_behaves_like 'a working graphql query' do
    before do
      request
    end
  end

  it 'matches the JSON schema' do
    request

    expect(repository_response).to match_schema('graphql/google_cloud/artifact_registry/repository')
  end

  it_behaves_like 'returning the expected response', end_cursor: 'next_page_token'

  context 'with arguments' do
    let(:page_token) { 'prev_page_token' }
    let(:order_by) { 'update_time desc' }
    let(:page_size) { 10 }

    let(:params) do
      { sort: :UPDATE_TIME_DESC, after: page_token, first: page_size }
    end

    it_behaves_like 'returning the expected response', end_cursor: 'next_page_token', start_cursor: 'prev_page_token'

    context 'with invalid `sort` argument' do
      let(:params) do
        { sort: :INVALID }
      end

      it 'returns the error' do
        request

        expect_graphql_errors_to_include(
          "Argument 'sort' on Field 'artifacts' " \
          "has an invalid value (INVALID). Expected type 'GoogleCloudArtifactRegistryArtifactsSort'."
        )
      end
    end
  end

  context 'when an user does not have required permissions' do
    let(:user) { create(:user).tap { |user| project.add_guest(user) } }

    it { is_expected.to be_nil }
  end

  context 'when google artifact registry feature is unavailable' do
    before do
      stub_saas_features(google_cloud_support: false)
    end

    it { is_expected.to be_nil }
  end

  context 'when gcp_artifact_registry FF is disabled' do
    before do
      stub_feature_flags(gcp_artifact_registry: false)
    end

    it { is_expected.to be_nil }
  end

  context 'when Google Cloud Artifact Registry integration is not present' do
    before do
      project_integration.destroy!
    end

    it { is_expected.to be_nil }
  end

  context 'when Google Cloud Artifact Registry integration is inactive' do
    before do
      project_integration.update_column(:active, false)
    end

    it { is_expected.to be_nil }
  end

  def dummy_list_docker_images_response
    Google::Cloud::ArtifactRegistry::V1::ListDockerImagesResponse.new(
      docker_images: [docker_image],
      next_page_token: 'next_page_token'
    )
  end
end
