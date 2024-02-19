# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloudPlatform::Compute::Client, feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
  let_it_be(:rsa_key_data) { rsa_key.to_s }
  let_it_be(:project_integration) { create(:google_cloud_platform_artifact_registry_integration, project: project) }

  let(:google_cloud_project_id) { 'project_id' }
  let(:google_cloud_identity_provider_resource_name) { '//identity.provider.resource.name.test' }

  let(:user) { project.owner }
  let(:client) do
    described_class.new(
      project_integration: project_integration,
      user: user
    )
  end

  shared_context 'with a client double' do |client_klass:|
    let(:client_double) { instance_double(client_klass.to_s) }
    let(:config_double) { instance_double("#{client_klass}::Configuration") }
    let(:dummy_response) { Object.new }

    before do
      stub_saas_features(google_cloud_support: true)
      stub_application_setting(ci_jwt_signing_key: rsa_key_data)
      stub_authentication_requests

      allow(config_double).to receive(:endpoint=).with('https://compute.googleapis.com')
      allow(config_double).to receive(:credentials=)
        .with(instance_of(::Google::Cloud::Compute::V1::Instances::Credentials))
      allow(client_klass).to receive(:new) do |_, &block|
        block.call(config_double)
        client_double
      end

      # required so that google auth gem will not trigger any API request
      allow(project_integration).to receive(:identity_provider_resource_name)
          .and_return('//identity.provider.resource.name.test')
    end
  end

  shared_examples 'handling errors' do |client_method:|
    shared_examples 'transforming the error' do |message:, from_klass:, to_klass:|
      it "translates the error from #{from_klass} to #{to_klass}" do
        expect(client_double).to receive(client_method).and_raise(from_klass, message)

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

    context 'with a nil project integration' do
      let(:project_integration) { nil }
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

    context 'when not on saas' do
      before do
        stub_saas_features(google_cloud_support: false)
      end

      it_behaves_like 'raising an error with', RuntimeError, described_class::SAAS_ONLY_ERROR_MESSAGE
    end
  end

  describe '#regions' do
    include_context 'with a client double', client_klass: Google::Cloud::Compute::V1::Regions::Rest::Client

    let(:filter) { nil }
    let(:max_results) { 500 }
    let(:page_token) { nil }
    let(:order_by) { nil }
    let(:list_response) do
      instance_double('Gapic::Rest::PagedEnumerable', response: { items: dummy_response, next_page_token: 'token' })
    end

    subject(:regions) do
      client.regions(filter: filter, max_results: max_results, order_by: order_by, page_token: page_token)
    end

    shared_examples 'returning the expected response' do
      it 'returns the expected response' do
        expect(client_double).to receive(:list) do |request|
          expect(request).to be_a ::Google::Cloud::Compute::V1::ListRegionsRequest
          expect(request.filter).to eq(filter.to_s)
          expect(request.max_results).to eq(max_results)
          expect(request.page_token).to eq(page_token.to_s)
          expect(request.order_by).to eq(order_by.to_s)

          list_response
        end

        expect(regions).to eq(items: dummy_response, next_page_token: 'token')
      end
    end

    it_behaves_like 'returning the expected response'

    context 'with a filter set' do
      let(:filter) { 'filter' }

      it_behaves_like 'returning the expected response'
    end

    context 'with max_results set' do
      let(:max_results) { 10 }

      it_behaves_like 'returning the expected response'
    end

    context 'with a page token set' do
      let(:page_token) { 'token' }

      it_behaves_like 'returning the expected response'
    end

    context 'with an order by set' do
      let(:order_by) { :name }

      it_behaves_like 'returning the expected response'
    end

    it_behaves_like 'handling errors', client_method: :list
  end

  describe '#zones' do
    include_context 'with a client double', client_klass: Google::Cloud::Compute::V1::Zones::Rest::Client

    let(:filter) { nil }
    let(:max_results) { 500 }
    let(:page_token) { nil }
    let(:order_by) { nil }
    let(:list_response) do
      instance_double('Gapic::Rest::PagedEnumerable', response: { items: dummy_response, next_page_token: 'token' })
    end

    subject(:zones) do
      client.zones(filter: filter, max_results: max_results, order_by: order_by, page_token: page_token)
    end

    shared_examples 'returning the expected response' do
      it 'returns the expected response' do
        expect(client_double).to receive(:list) do |request|
          expect(request).to be_a ::Google::Cloud::Compute::V1::ListZonesRequest
          expect(request.filter).to eq(filter.to_s)
          expect(request.max_results).to eq(max_results)
          expect(request.page_token).to eq(page_token.to_s)
          expect(request.order_by).to eq(order_by.to_s)

          list_response
        end

        expect(zones).to eq(items: dummy_response, next_page_token: 'token')
      end
    end

    it_behaves_like 'returning the expected response'

    context 'with a filter set' do
      let(:filter) { 'filter' }

      it_behaves_like 'returning the expected response'
    end

    context 'with max_results set' do
      let(:max_results) { 10 }

      it_behaves_like 'returning the expected response'
    end

    context 'with a page token set' do
      let(:page_token) { 'token' }

      it_behaves_like 'returning the expected response'
    end

    context 'with an order by set' do
      let(:order_by) { :name }

      it_behaves_like 'returning the expected response'
    end

    it_behaves_like 'handling errors', client_method: :list
  end

  describe '#machine_types' do
    include_context 'with a client double', client_klass: Google::Cloud::Compute::V1::MachineTypes::Rest::Client

    let(:zone) { 'europe-west4-a' }
    let(:filter) { nil }
    let(:max_results) { 500 }
    let(:page_token) { nil }
    let(:order_by) { nil }
    let(:list_response) do
      instance_double('Gapic::Rest::PagedEnumerable', response: { items: dummy_response, next_page_token: 'token' })
    end

    subject(:machine_types) do
      client.machine_types(
        zone: zone, filter: filter, max_results: max_results, order_by: order_by, page_token: page_token
      )
    end

    shared_examples 'returning the expected response' do
      it 'returns the expected response' do
        expect(client_double).to receive(:list) do |request|
          expect(request).to be_a ::Google::Cloud::Compute::V1::ListMachineTypesRequest
          expect(request.zone).to eq(zone.to_s)
          expect(request.filter).to eq(filter.to_s)
          expect(request.max_results).to eq(max_results)
          expect(request.page_token).to eq(page_token.to_s)
          expect(request.order_by).to eq(order_by.to_s)

          list_response
        end

        expect(machine_types).to eq(items: dummy_response, next_page_token: 'token')
      end
    end

    it_behaves_like 'returning the expected response'

    context 'with a filter set' do
      let(:filter) { 'filter' }

      it_behaves_like 'returning the expected response'
    end

    context 'with max_results set' do
      let(:max_results) { 10 }

      it_behaves_like 'returning the expected response'
    end

    context 'with a page token set' do
      let(:page_token) { 'token' }

      it_behaves_like 'returning the expected response'
    end

    context 'with an order by set' do
      let(:order_by) { :name }

      it_behaves_like 'returning the expected response'
    end

    it_behaves_like 'handling errors', client_method: :list
  end

  def stub_authentication_requests
    stub_request(:get, ::GoogleCloudPlatform::GLGO_TOKEN_ENDPOINT_URL)
      .to_return(status: 200, body: ::Gitlab::Json.dump(token: 'token'))
    stub_request(:post, ::GoogleCloudPlatform::STS_URL)
      .to_return(status: 200, body: ::Gitlab::Json.dump(token: 'token'))
  end
end
