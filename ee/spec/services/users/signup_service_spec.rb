# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SignupService, feature_category: :system_access do
  let_it_be(:user) { create(:user, setup_for_company: true) }
  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(user, params).execute }

    context 'when updating name' do
      let(:params) { { name: 'New Name' } }

      it 'updates the name attribute' do
        expect(execute).to be_success
        expect(execute[:user].name).to eq('New Name')
      end

      context 'when name is missing' do
        let(:params) { { name: '' } }

        it 'returns an error result' do
          expect(execute[:user].name).not_to be_blank
          expect(execute).to be_error
          expect(execute.message).to include("Name can't be blank")
        end
      end
    end

    context 'when updating role' do
      let(:params) { { role: 'development_team_lead' } }

      it 'updates the role attribute' do
        expect(execute).to be_success
        expect(execute[:user].role).to eq('development_team_lead')
      end

      context 'when role is missing' do
        let(:params) { { role: '' } }

        it 'returns an error result' do
          expect(execute[:user].role).not_to be_blank
          expect(execute).to be_error
          expect(execute.message).to eq("Role can't be blank")
        end
      end
    end

    context 'when updating setup_for_company' do
      let(:params) { { setup_for_company: 'false' } }

      it 'updates the setup_for_company attribute' do
        expect(execute).to be_success
        expect(execute[:user].setup_for_company).to be(false)
      end

      context 'when setup_for_company is missing' do
        let(:params) { { setup_for_company: '' } }

        it 'returns an error result' do
          expect(execute[:user].setup_for_company).not_to be_blank
          expect(execute).to be_error
          expect(execute.message).to eq("Setup for company can't be blank")
        end
      end
    end

    context 'for logged errors' do
      let(:params) { { onboarding_status: { unsupported_key: '_some_value_' } } }

      it 'logs the errors from active record and the onboarding_status' do
        expect(Gitlab::AppLogger).to receive(:error).with(/#{described_class}: Could not save/)

        execute
      end
    end
  end
end
