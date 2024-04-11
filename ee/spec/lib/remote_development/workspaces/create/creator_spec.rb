# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::Creator, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers
  include ResultMatchers

  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:random_string) { 'abcdef' }

  let(:params) do
    {
      agent: agent
    }
  end

  let(:value) do
    {
      params: params,
      current_user: user
    }
  end

  let(:updated_value) do
    value.merge(
      {
        workspace_name: "workspace-#{agent.id}-#{user.id}-#{random_string}",
        workspace_namespace: "gl-rd-ns-#{agent.id}-#{user.id}-#{random_string}"
      }
    )
  end

  # Classes

  let(:personal_access_token_creator_class) { RemoteDevelopment::Workspaces::Create::PersonalAccessTokenCreator }
  let(:workspace_creator_class) { RemoteDevelopment::Workspaces::Create::WorkspaceCreator }
  let(:workspace_variables_creator_class) { RemoteDevelopment::Workspaces::Create::WorkspaceVariablesCreator }

  # Methods

  let(:personal_access_token_creator_method) { personal_access_token_creator_class.singleton_method(:create) }
  let(:workspace_creator_method) { workspace_creator_class.singleton_method(:create) }
  let(:workspace_variables_creator_method) { workspace_variables_creator_class.singleton_method(:create) }

  subject(:result) do
    described_class.create(value) # rubocop:disable Rails/SaveBang -- we are testing validation, we don't want an exception
  end

  before do
    allow(personal_access_token_creator_class).to receive(:method).with(:create) do
      personal_access_token_creator_method
    end

    allow(workspace_creator_class).to receive(:method).with(:create) do
      workspace_creator_method
    end

    allow(workspace_variables_creator_class).to receive(:method).with(:create) do
      create(:workspace_variable)
      workspace_variables_creator_method
    end
  end

  context 'when workspace create is successful' do
    before do
      allow(SecureRandom).to receive(:alphanumeric) { random_string }

      stub_methods_to_return_ok_result(
        personal_access_token_creator_method,
        workspace_creator_method,
        workspace_variables_creator_method
      )
    end

    it 'returns ok result containing successful message with updated value' do
      expect(result).to be_ok_result do |message|
        expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateSuccessful)
        expect(message.context).to eq(updated_value)
      end
    end
  end

  context "when workspace create fails" do
    let(:creation_errors) { 'some creation errors' }
    let(:err_message_context) { { errors: creation_errors } }

    context 'when the PersonalAccessTokenCreator returns an err Result' do
      before do
        stub_methods_to_return_err_result(
          method: personal_access_token_creator_method,
          message_class: RemoteDevelopment::Messages::PersonalAccessTokenModelCreateFailed
        )
      end

      it 'returns an error result containing creation errors' do
        expect(result).to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateFailed)
          message.context => { errors: errors }
          expect(errors).to eq(creation_errors)
        end
      end
    end

    context 'when the WorkspaceCreator returns an err Result' do
      before do
        stub_methods_to_return_ok_result(personal_access_token_creator_method)

        stub_methods_to_return_err_result(
          method: workspace_creator_method,
          message_class: RemoteDevelopment::Messages::WorkspaceModelCreateFailed
        )
      end

      it 'returns an error result containing creation errors' do
        expect(result).to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateFailed)
          message.context => { errors: errors }
          expect(errors).to eq(creation_errors)
        end
      end
    end

    context 'when the WorkspaceVariablesCreator returns an err Result' do
      before do
        stub_methods_to_return_ok_result(
          personal_access_token_creator_method,
          workspace_creator_method
        )

        stub_methods_to_return_err_result(
          method: workspace_variables_creator_method,
          message_class: RemoteDevelopment::Messages::WorkspaceVariablesModelCreateFailed
        )
      end

      it 'returns an error response containing creation errors' do
        expect(result).to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateFailed)
          message.context => { errors: errors }
          expect(errors).to eq(creation_errors)
        end
      end
    end
  end
end
