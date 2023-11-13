# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::SyncServiceAccessTokenService, :freeze_time, feature_category: :cloud_connector do
  describe '#execute' do
    shared_examples 'returns error with proper message' do |message|
      it 'returns error' do
        expect(sync_service_access_token.error?).to eq(true)
      end

      it 'returns error message' do
        expect(sync_service_access_token[:message]).to eq(message)
      end
    end

    shared_examples 'no service token sync' do |message|
      it 'does not execute SubscriptionPortal GraphQl service_token query' do
        expect(Gitlab::SubscriptionPortal::Client).not_to receive(:get_service_token)

        sync_service_access_token
      end

      include_examples 'returns error with proper message', message
    end

    shared_examples 'service token sync' do
      before do
        allow(Gitlab::SubscriptionPortal::Client).to receive(:get_service_token).and_return(response)
      end

      context 'when graphql query response is successful' do
        let(:response) { { success: true, token: token, expires_at: expires_at } }
        let(:storage_service_response) { ServiceResponse.success }
        let(:token) { 'token' }
        let(:expires_at) { Time.current.iso8601.to_s }

        before do
          allow_next_instance_of(Ai::ServiceAccessTokensStorageService, token, expires_at) do |service|
            allow(service).to receive(:execute).and_return(storage_service_response)
          end
        end

        it 'executed SubscriptionPortal GraphQl service_token query' do
          expect(Gitlab::SubscriptionPortal::Client).to receive(:get_service_token)

          sync_service_access_token
        end

        context 'when token is successfully stored' do
          it 'returns successful response' do
            expect(sync_service_access_token.success?).to eq(true)
          end
        end

        context 'when token is not successfully stored' do
          let(:storage_service_response) { ServiceResponse.error(message: 'Error') }

          include_examples 'returns error with proper message', 'Error'
        end
      end

      context 'when graphql query response is not successful' do
        let(:response) { { success: false, errors: ["Error"] } }

        include_examples 'returns error with proper message', 'Error'
      end
    end

    subject(:sync_service_access_token) { described_class.new.execute }

    context 'with license checks' do
      context 'when license is valid cloud license' do
        before do
          # Setting the date as 12th March 2020 12:00 UTC for tests and creating new license
          create_current_license(cloud_licensing_enabled: true, starts_at: '2020-02-12'.to_date)
        end

        include_examples 'service token sync'
      end

      context 'when license is missing' do
        before do
          License.current.destroy!
        end

        include_examples 'no service token sync', 'License not found'
      end

      context 'when using a trial license' do
        before do
          create_current_license(cloud_licensing_enabled: true, restrictions: { trial: true })
        end

        include_examples 'no service token sync', 'License can\'t be on trial'
      end

      context 'when the license has no expiration date' do
        before do
          create_current_license_without_expiration(cloud_licensing_enabled: true, block_changes_at: nil)
        end

        include_examples 'no service token sync', 'License has no expiration date'
      end

      context 'when using an expired license' do
        before do
          create_current_license(cloud_licensing_enabled: true, expires_at: Time.zone.now.utc.to_date - 10.days)
        end

        include_examples 'service token sync'
      end

      context 'when using an expired license, and grace period has passed' do
        before do
          create_current_license(cloud_licensing_enabled: true, expires_at: Time.zone.now.utc.to_date - 15.days)
        end

        include_examples 'no service token sync', 'License grace period has been expired'
      end

      context 'with a non offline cloud license' do
        before do
          create_current_license(cloud_licensing_enabled: true, offline_cloud_licensing_enabled: true)
        end

        include_examples 'no service token sync', 'License is not an online cloud license'
      end

      context 'with a non cloud license' do
        before do
          create_current_license(starts_at: '2020-02-12'.to_date)
        end

        include_examples 'no service token sync', 'License is not an online cloud license'
      end
    end
  end
end
