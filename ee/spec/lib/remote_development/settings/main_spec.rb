# frozen_string_literal: true

require_relative '../rd_fast_spec_helper'

RSpec.describe RemoteDevelopment::Settings::Main, :rd_fast, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:settings) { { some_setting: 42 } }
  let(:value) { { settings: settings } }
  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }

  # Classes

  let(:defaults_initializer_class) { RemoteDevelopment::Settings::DefaultsInitializer }
  let(:current_settings_reader_class) { RemoteDevelopment::Settings::CurrentSettingsReader }
  let(:env_var_reader_class) { RemoteDevelopment::Settings::EnvVarReader }
  let(:extensions_gallery_validator_class) { RemoteDevelopment::Settings::ExtensionsGalleryValidator }

  # Methods

  let(:defaults_initializer_method) { defaults_initializer_class.singleton_method(:init) }
  let(:current_settings_reader_method) { current_settings_reader_class.singleton_method(:read) }
  let(:env_var_reader_method) { env_var_reader_class.singleton_method(:read) }
  let(:extensions_gallery_validator_method) do
    extensions_gallery_validator_class.singleton_method(:validate)
  end

  # Subject

  subject(:response) { described_class.get_settings }

  before do
    allow(defaults_initializer_class).to receive(:method).with(:init) { defaults_initializer_method }
    allow(current_settings_reader_class).to receive(:method).with(:read) { current_settings_reader_method }
    allow(env_var_reader_class).to receive(:method).with(:read) { env_var_reader_method }
    allow(extensions_gallery_validator_class).to receive(:method).with(:validate) do
      extensions_gallery_validator_method
    end

    stub_method_to_modify_and_return_value(defaults_initializer_method, expected_value: {}, returned_value: value)
  end

  context 'when all steps are successful' do
    before do
      stub_methods_to_return_ok_result(current_settings_reader_method, env_var_reader_method,
        extensions_gallery_validator_method)
    end

    it 'returns a success response with the settings as the payload' do
      expect(response).to eq({
        status: :success,
        settings: settings
      })
    end
  end

  context 'when the CurrentSettingsReader returns an err Result' do
    before do
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

  context 'when the EnvVarReader returns an err Result' do
    before do
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

  context 'when the ExtensionsGalleryValidator returns an err Result' do
    before do
      stub_methods_to_return_ok_result(current_settings_reader_method, env_var_reader_method)
      stub_methods_to_return_err_result(
        method: extensions_gallery_validator_method,
        message_class: RemoteDevelopment::Messages::SettingsVscodeExtensionsGalleryValidationFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Settings VSCode extensions gallery validation failed: #{error_details}",
        reason: :internal_server_error
      })
    end
  end

  context 'when an invalid Result is returned' do
    before do
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
