# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SshCertificates::FindService, feature_category: :source_code_management do
  let_it_be(:ssh_certificate) { create(:group_ssh_certificate) }
  let_it_be(:group) { ssh_certificate.group }
  let_it_be(:user) { create(:user, :enterprise_user, enterprise_group: group) }

  let(:ca_fingerprint) { ssh_certificate.fingerprint }
  let(:user_identifier) { user.username }
  let(:service) { described_class.new(ca_fingerprint, user_identifier) }

  before_all do
    group.add_developer(user)
  end

  before do
    stub_licensed_features(ssh_certificates: true)
  end

  describe '#execute' do
    it 'returns successful response with payload' do
      response = service.execute

      expect(response).to be_success
      expect(response.payload).to eq({ user: user, group: group })
    end

    context 'when a certificate not found' do
      let(:ca_fingerprint) { 'does not exist' }

      it 'returns not found error' do
        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('Certificate Not Found')
        expect(response.reason).to eq(:not_found)
      end
    end

    context 'when ssh_certificates feature is not available' do
      it 'returns forbidden error' do
        stub_licensed_features(ssh_certificates: false)

        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('Feature is not available')
        expect(response.reason).to eq(:forbidden)
      end
    end

    context 'when a user is not found' do
      let(:user_identifier) { 'does not exist' }

      it 'returns not found error' do
        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('User Not Found')
        expect(response.reason).to eq(:not_found)
      end
    end

    context 'when a user is not a member' do
      let_it_be(:user) { create(:user) }

      it 'returns not found error' do
        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('User Not Found')
        expect(response.reason).to eq(:not_found)
      end
    end

    context 'when a user is not an enterprise user' do
      let_it_be(:user) { create(:user) }

      it 'returns not found error' do
        group.add_developer(user)

        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('Not an Enterprise User of the group')
        expect(response.reason).to eq(:forbidden)
      end
    end
  end
end
