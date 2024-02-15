# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloudPlatform::ArtifactRegistry::Client, feature_category: :container_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
  let_it_be(:rsa_key_data) { rsa_key.to_s }

  let(:gcp_project_id) { 'gcp_project_id' }
  let(:gcp_location) { 'gcp_location' }
  let(:gcp_repository) { 'gcp_repository' }
  let(:gcp_wlif) { '//wlif.test' }

  let(:user) { project.owner }
  let(:client) do
    described_class.new(
      project: project,
      user: user,
      gcp_project_id: gcp_project_id,
      gcp_location: gcp_location,
      gcp_repository: gcp_repository,
      gcp_wlif: gcp_wlif
    )
  end

  shared_context 'with a gcp client double' do
    let(:gcp_client_double) { instance_double('::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Client') }
    let(:config_double) do
      instance_double('Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Client::Configuration')
    end

    let(:dummy_response) { Object.new }

    before do
      stub_saas_features(google_cloud_support: true)
      stub_application_setting(ci_jwt_signing_key: rsa_key_data)
      stub_authentication_requests

      allow(config_double).to receive(:credentials=)
        .with(instance_of(::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Credentials))
      allow(::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Client).to receive(:new) do |_, &block|
        block.call(config_double)
        gcp_client_double
      end
    end
  end

  shared_examples 'handling errors' do |gcp_client_method:|
    shared_examples 'transforming the error' do |message:, from_klass:, to_klass:|
      it "translates the error from #{from_klass} to #{to_klass}" do
        expect(gcp_client_double).to receive(gcp_client_method).and_raise(from_klass, message)

        expect { subject }.to raise_error(to_klass, message)
      end
    end

    it_behaves_like 'transforming the error',
      message: "test #{described_class::GCP_SUBJECT_TOKEN_ERROR_MESSAGE} test",
      from_klass: RuntimeError,
      to_klass: ::GoogleCloudPlatform::AuthenticationError

    it_behaves_like 'transforming the error',
      message: "test #{described_class::GCP_TOKEN_EXCHANGE_ERROR_MESSAGE} test",
      from_klass: RuntimeError,
      to_klass: ::GoogleCloudPlatform::AuthenticationError

    it_behaves_like 'transforming the error',
      message: "test",
      from_klass: RuntimeError,
      to_klass: RuntimeError

    it_behaves_like 'transforming the error',
      message: "test",
      from_klass: ::Google::Cloud::Error,
      to_klass: ::GoogleCloudPlatform::ApiError
  end

  describe 'validations' do
    before do
      stub_saas_features(google_cloud_support: true)
    end

    shared_examples 'raising an error with' do |klass, message|
      it "raises #{klass} error" do
        expect { client }.to raise_error(klass, message)
      end
    end

    context 'with a nil project' do
      let(:project) { nil }
      let(:user) { build(:user) }

      it_behaves_like 'raising an error with',
        ArgumentError,
        ::GoogleCloudPlatform::BaseClient::BLANK_PARAMETERS_ERROR_MESSAGE
    end

    context 'with a nil user' do
      let(:user) { nil }

      it_behaves_like 'raising an error with',
        ArgumentError,
        ::GoogleCloudPlatform::BaseClient::BLANK_PARAMETERS_ERROR_MESSAGE
    end

    %i[gcp_project_id gcp_location gcp_repository gcp_wlif].each do |field|
      context "with a nil #{field}" do
        let(field) { nil }

        it_behaves_like 'raising an error with', ArgumentError, described_class::BLANK_PARAMETERS_ERROR_MESSAGE
      end
    end

    context 'when not on saas' do
      before do
        stub_saas_features(google_cloud_support: false)
      end

      it_behaves_like 'raising an error with', RuntimeError, described_class::SAAS_ONLY_ERROR_MESSAGE
    end
  end

  describe '#repository' do
    include_context 'with a gcp client double'

    subject(:repository) { client.repository }

    it 'returns the expected response' do
      expect(gcp_client_double).to receive(:get_repository)
        .with(instance_of(::Google::Cloud::ArtifactRegistry::V1::GetRepositoryRequest))
        .and_return(dummy_response)

      expect(repository).to eq(dummy_response)
    end

    it_behaves_like 'handling errors', gcp_client_method: :get_repository
  end

  describe '#docker_images' do
    include_context 'with a gcp client double'

    let(:page_size) { nil }
    let(:page_token) { nil }
    let(:order_by) { nil }
    let(:list_response) do
      instance_double(
        'Gapic::PagedEnumerable',
        response: { docker_images: dummy_response, next_page_token: 'token' }
      )
    end

    subject(:docker_images) { client.docker_images(page_size: page_size, page_token: page_token, order_by: order_by) }

    shared_examples 'returning the expected response' do |expected_page_size: described_class::DEFAULT_PAGE_SIZE|
      it 'returns the expected response' do
        expect(gcp_client_double).to receive(:list_docker_images) do |request|
          expect(request).to be_a ::Google::Cloud::ArtifactRegistry::V1::ListDockerImagesRequest
          expect(request.page_size).to eq(expected_page_size)
          expect(request.page_token).to eq(page_token.to_s)
          expect(request.order_by).to eq(order_by.to_s)

          list_response
        end

        expect(docker_images).to eq(docker_images: dummy_response, next_page_token: 'token')
      end
    end

    it_behaves_like 'returning the expected response'

    context 'with a page size set' do
      let(:page_size) { 20 }

      it_behaves_like 'returning the expected response', expected_page_size: 20
    end

    context 'with a page token set' do
      let(:page_token) { 'token' }

      it_behaves_like 'returning the expected response'
    end

    context 'with an order by set' do
      let(:order_by) { :name }

      it_behaves_like 'returning the expected response'
    end

    it_behaves_like 'handling errors', gcp_client_method: :list_docker_images
  end

  describe '#docker_image' do
    include_context 'with a gcp client double'

    let(:name) { 'test' }

    subject(:docker_image) { client.docker_image(name: name) }

    it 'returns the expected response' do
      expect(gcp_client_double).to receive(:get_docker_image) do |request|
        expect(request).to be_a ::Google::Cloud::ArtifactRegistry::V1::GetDockerImageRequest
        expect(request.name).to eq(name)

        dummy_response
      end

      expect(docker_image).to eq(dummy_response)
    end

    it_behaves_like 'handling errors', gcp_client_method: :get_docker_image
  end

  def stub_authentication_requests
    stub_request(:get, ::GoogleCloudPlatform::GLGO_TOKEN_ENDPOINT_URL)
      .to_return(status: 200, body: ::Gitlab::Json.dump(token: 'token'))
    stub_request(:post, ::GoogleCloudPlatform::STS_URL)
      .to_return(status: 200, body: ::Gitlab::Json.dump(token: 'token'))
  end
end
