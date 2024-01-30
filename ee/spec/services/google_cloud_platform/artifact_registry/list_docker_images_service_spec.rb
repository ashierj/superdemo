# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloudPlatform::ArtifactRegistry::ListDockerImagesService, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }

  let(:user) { project.owner }
  let(:gcp_project_id) { 'gcp_project_id' }
  let(:gcp_location) { 'gcp_location' }
  let(:gcp_repository) { 'gcp_repository' }
  let(:gcp_wlif) { 'https://wlif.test' }
  let(:service) do
    described_class.new(
      project: project,
      current_user: user,
      params: {
        gcp_project_id: gcp_project_id,
        gcp_location: gcp_location,
        gcp_repository: gcp_repository,
        gcp_wlif: gcp_wlif
      }
    )
  end

  describe '#execute' do
    let(:page_token) { 'token' }
    let(:order_by) { :name }
    let(:list_docker_images_response) { dummy_list_response }
    let(:client_double) { instance_double('::GoogleCloudPlatform::ArtifactRegistry::Client') }

    before do
      allow(::GoogleCloudPlatform::ArtifactRegistry::Client).to receive(:new)
        .with(
          project: project,
          user: user,
          gcp_project_id: gcp_project_id,
          gcp_location: gcp_location,
          gcp_repository: gcp_repository,
          gcp_wlif: gcp_wlif
        ).and_return(client_double)
      allow(client_double).to receive(:docker_images)
        .with(page_token: page_token, order_by: order_by)
        .and_return(list_docker_images_response)
    end

    subject(:list) { service.execute(page_token: page_token, order_by: order_by) }

    it 'returns the docker images' do
      expect(list).to be_success
      expect(list.payload).to be_a Google::Cloud::ArtifactRegistry::V1::ListDockerImagesResponse
      expect(list.payload.docker_images).to be_a Enumerable
      expect(list.payload.next_page_token).to eq('next_page_token')
    end

    context 'with not enough permissions' do
      let_it_be(:user) { create(:user) }

      it 'returns an error response' do
        expect(list).to be_error
        expect(list.message).to eq('Access denied')
      end
    end

    private

    def dummy_list_response
      Google::Cloud::ArtifactRegistry::V1::ListDockerImagesResponse.new(
        docker_images: [::Google::Cloud::ArtifactRegistry::V1::DockerImage.new],
        next_page_token: 'next_page_token'
      )
    end
  end
end
