# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::NamespaceClusterAgentMappings::Delete::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }
  let(:value) { {} }

  let(:mapping_deleter_class) { RemoteDevelopment::NamespaceClusterAgentMappings::Delete::MappingDeleter }

  let(:delete_method) { mapping_deleter_class.singleton_method(:delete) }

  subject(:response) { described_class.main(value) }

  before do
    allow(mapping_deleter_class).to receive(:method) { delete_method }
  end

  context 'when the MappingDeleter returns an err Result' do
    before do
      stub_methods_to_return_err_result(
        method: delete_method,
        message_class: RemoteDevelopment::Messages::NamespaceClusterAgentMappingNotFound
      )
    end

    it 'returns a validation failed error response' do
      expect(response).to eq({
        status: :error,
        message: "Namespace cluster agent mapping not found: #{error_details}",
        reason: :bad_request
      })
    end
  end

  context 'when the MappingDeleter returns an ok Result' do
    before do
      stub_methods_to_return_ok_result(
        delete_method
      )
      allow(delete_method).to receive(:call).with(value) do
        Result.ok(RemoteDevelopment::Messages::NamespaceClusterAgentMappingDeleteSuccessful.new({}))
      end
    end

    it 'return a success response with an empty payload' do
      expect(response).to eq({
        status: :success,
        payload: {}
      })
    end
  end

  context 'when an invalid Result is returned' do
    before do
      allow(delete_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::NamespaceClusterAgentMappingDeleteSuccessful.new({}))
      end
    end

    it 'raises an UnmatchedResultError' do
      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
