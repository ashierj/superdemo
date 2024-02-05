# frozen_string_literal: true

RSpec.shared_examples 'an artifact registry service handling validation errors' do |client_method:|
  it_behaves_like 'returning an error service response',
    message: described_class::ERROR_RESPONSES[:saas_only].message

  context 'with saas only feature enabled' do
    before do
      stub_saas_features(google_artifact_registry: true)
    end

    shared_examples 'logging an error' do |message:|
      it 'logs an error' do
        expect(service).to receive(:log_error)
          .with(class_name: described_class.name, project_id: project.id, message: message)

        subject
      end
    end

    context 'with not enough permissions' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'returning an error service response',
        message: described_class::ERROR_RESPONSES[:access_denied].message
    end

    context 'with gcp_artifact_registry disabled' do
      before do
        stub_feature_flags(gcp_artifact_registry: false)
      end

      it_behaves_like 'returning an error service response',
        message: described_class::ERROR_RESPONSES[:feature_flag_disabled].message
    end

    context 'with no integration' do
      before do
        project_integration.destroy!
      end

      it_behaves_like 'returning an error service response',
        message: described_class::ERROR_RESPONSES[:no_project_integration].message
    end

    context 'with disabled integration' do
      before do
        project_integration.update!(active: false)
      end

      it_behaves_like 'returning an error service response',
        message: described_class::ERROR_RESPONSES[:project_integration_disabled].message
    end

    context 'when client raises AuthenticationError' do
      before do
        allow(client_double).to receive(client_method)
          .and_raise(::GoogleCloudPlatform::AuthenticationError, 'boom')
      end

      it_behaves_like 'returning an error service response', message: described_class::GCP_AUTHENTICATION_ERROR_MESSAGE
      it_behaves_like 'logging an error', message: 'boom'
    end

    context 'when client raises ApiError' do
      before do
        allow(client_double).to receive(client_method)
          .and_raise(::GoogleCloudPlatform::ApiError, 'boom')
      end

      it_behaves_like 'returning an error service response', message: described_class::GCP_API_ERROR_MESSAGE
      it_behaves_like 'logging an error', message: 'boom'
    end
  end
end
