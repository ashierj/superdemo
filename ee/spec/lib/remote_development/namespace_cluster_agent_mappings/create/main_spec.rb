# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::NamespaceClusterAgentMappings::Create::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }
  let(:value) { {} }

  let(:validator_class) { RemoteDevelopment::NamespaceClusterAgentMappings::Create::ClusterAgentValidator }
  let(:mapping_creator_class) { RemoteDevelopment::NamespaceClusterAgentMappings::Create::MappingCreator }

  let(:validator_method) { validator_class.singleton_method(:validate) }
  let(:creator_method) { mapping_creator_class.singleton_method(:create) }

  subject(:response) { described_class.main(value) }

  before do
    allow(validator_class).to receive(:method) { validator_method }
    allow(mapping_creator_class).to receive(:method) { creator_method }
  end

  context 'when the ClusterAgentValidator returns an err Result' do
    before do
      allow(validator_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::NamespaceClusterAgentMappingCreateValidationFailed.new)
      end
    end

    it 'returns a validation failed error response' do
      expect(response).to eq({
        status: :error,
        message: 'Namespace cluster agent mapping create validation failed',
        reason: :bad_request
      })
    end
  end

  context 'when the MappingCreator returns an err Result' do
    shared_examples 'returns an error response' do |message_class, message|
      before do
        stub_methods_to_return_ok_result(
          validator_method
        )
        stub_methods_to_return_err_result(
          method: creator_method,
          message_class: message_class
        )
      end

      it 'returns a validation failed error response' do
        expect(response).to eq({
          status: :error,
          message: "#{message}: #{error_details}",
          reason: :bad_request
        })
      end
    end

    it_behaves_like 'returns an error response',
      RemoteDevelopment::Messages::NamespaceClusterAgentMappingAlreadyExists,
      "Namespace cluster agent mapping already exists"
    it_behaves_like 'returns an error response',
      RemoteDevelopment::Messages::NamespaceClusterAgentMappingCreateFailed,
      "Namespace cluster agent mapping create failed"
  end

  context 'when the MappingCreator returns an ok Result' do
    let(:namespace_agent_mapping) do
      instance_double('RemoteDevelopment::RemoteDevelopmentNamespaceClusterAgentMapping')
    end

    before do
      stub_methods_to_return_ok_result(
        validator_method,
        creator_method
      )
      allow(creator_method).to receive(:call).with(value) do
        Result.ok(RemoteDevelopment::Messages::NamespaceClusterAgentMappingCreateSuccessful.new({
          namespace_cluster_agent_mapping: namespace_agent_mapping
        }))
      end
    end

    it 'return a success response with the namespace cluster agent mapping as the payload' do
      expect(response).to eq({
        status: :success,
        payload: { namespace_cluster_agent_mapping: namespace_agent_mapping }
      })
    end
  end

  context 'when an invalid Result is returned' do
    let(:namespace_agent_mapping) do
      instance_double('RemoteDevelopment::RemoteDevelopmentNamespaceClusterAgentMapping')
    end

    before do
      stub_methods_to_return_ok_result(
        validator_method,
        creator_method
      )
      allow(creator_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::NamespaceClusterAgentMappingCreateSuccessful.new({
          namespace_cluster_agent_mapping: namespace_agent_mapping
        }))
      end
    end

    it 'raises an UnmatchedResultError' do
      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
