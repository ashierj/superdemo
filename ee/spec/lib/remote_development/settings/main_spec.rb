# frozen_string_literal: true

require_relative '../fast_spec_helper'

RSpec.describe RemoteDevelopment::Settings::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:value) { {} }
  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }

  # Classes

  let(:defaults_initializer_class) { RemoteDevelopment::Settings::DefaultsInitializer }
  let(:current_settings_reader_class) { RemoteDevelopment::Settings::CurrentSettingsReader }
  let(:env_var_reader_class) { RemoteDevelopment::Settings::EnvVarReader }

  # Methods

  let(:defaults_initializer_method) { defaults_initializer_class.singleton_method(:init) }
  let(:current_settings_reader_method) { current_settings_reader_class.singleton_method(:read) }
  let(:env_var_reader_method) { env_var_reader_class.singleton_method(:read) }

  # Subject

  subject(:response) { described_class.get_settings }

  before do
    allow(defaults_initializer_class).to receive(:method) { defaults_initializer_method }
    allow(current_settings_reader_class).to(receive(:method)) { current_settings_reader_method }
    allow(env_var_reader_class).to(receive(:method)) { env_var_reader_method }
  end

  context 'when the CurrentSettingsReader returns an err Result' do
    before do
      stub_methods_to_return_value(defaults_initializer_method)
      stub_methods_to_return_err_result(
        method: current_settings_reader_method,
        message_class: RemoteDevelopment::Messages::SettingsCurrentSettingsReadFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Settings current settings read failed: #{error_details}",
        reason: :internal_server_error
      })
    end
  end

  context 'when the CurrentSettingsReader returns an ok Result' do
    before do
      stub_methods_to_return_value(defaults_initializer_method)
      allow(current_settings_reader_method).to receive(:call).with(value) do
        Result.ok({ settings: { int_setting: 1 } })
      end
    end

    it 'returns a settings get success response with the settings as the payload' do
      expect(response).to eq({
        status: :success,
        settings: { int_setting: 1 }
      })
    end
  end

  context 'when the EnvVarReader returns an err Result' do
    before do
      stub_methods_to_return_value(defaults_initializer_method)
      stub_methods_to_return_ok_result(current_settings_reader_method)
      stub_methods_to_return_err_result(
        method: env_var_reader_method,
        message_class: RemoteDevelopment::Messages::SettingsEnvironmentVariableReadFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Settings environment variable read failed: #{error_details}",
        reason: :internal_server_error
      })
    end
  end

  context 'when the EnvVarReader returns an ok Result' do
    before do
      stub_methods_to_return_value(defaults_initializer_method)
      stub_methods_to_return_ok_result(current_settings_reader_method)
      allow(env_var_reader_method).to receive(:call).with(value) do
        Result.ok({ settings: { int_setting: 1 } })
      end
    end

    it 'returns a settings get success response with the settings as the payload' do
      expect(response).to eq({
        status: :success,
        settings: { int_setting: 1 }
      })
    end
  end

  context 'when an invalid Result is returned' do
    before do
      stub_methods_to_return_value(defaults_initializer_method)
      stub_methods_to_return_ok_result(current_settings_reader_method)
      stub_methods_to_return_err_result(
        method: env_var_reader_method,
        message_class: RemoteDevelopment::Messages::WorkspaceCreateSuccessful
      )
    end

    it 'raises an UnmatchedResultError' do
      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
