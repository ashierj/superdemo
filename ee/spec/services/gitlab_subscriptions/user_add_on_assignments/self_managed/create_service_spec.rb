# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::UserAddOnAssignments::SelfManaged::CreateService, feature_category: :seat_cost_management do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
  let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: add_on) }
  let_it_be(:user) { create(:user) }

  subject(:response) do
    described_class.new(add_on_purchase: add_on_purchase, user: user).execute
  end

  before do
    stub_saas_features(code_suggestions: false)
  end

  describe '#execute' do
    let(:log_params) do
      {
        user: user.username,
        add_on: add_on_purchase.add_on.name
      }
    end

    shared_examples 'success response' do
      it 'creates new records' do
        expect(Gitlab::AppLogger).to receive(:info).with(log_params.merge(message: 'User AddOn assignment created'))

        expect { subject }.to change { add_on_purchase.assigned_users.where(user: user).count }.by(1)
        expect(response).to be_success
      end

      it 'expires the user add-on cache', :use_clean_rails_redis_caching do
        cache_key = format(User::CODE_SUGGESTIONS_ADD_ON_CACHE_KEY, user_id: user.id)
        Rails.cache.write(cache_key, false, expires_in: 1.hour)

        expect { subject }.to change { Rails.cache.read(cache_key) }.from(false).to(nil)
      end
    end

    shared_examples 'error response' do |error|
      it 'does not create new records' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          log_params.merge(
            {
              message: 'User AddOn assignment creation failed',
              error: error,
              error_code: 422
            }
          )
        )

        expect { subject }.not_to change { add_on_purchase.assigned_users.count }
        expect(response.errors).to include(error)
      end
    end

    it_behaves_like 'success response'

    context 'when user is already assigned' do
      before do
        create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: user)
      end

      it 'does not create new record' do
        expect { response }.not_to change { add_on_purchase.assigned_users.count }
        expect(response).to be_success
      end
    end

    context 'when seats are not available' do
      before do
        create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: create(:user))
      end

      it_behaves_like 'error response', 'NO_SEATS_AVAILABLE'
    end

    context 'when user is not eligible' do
      let(:user) { create(:user) }

      before do
        allow(user).to receive(:eligible_for_self_managed_code_suggestions?).and_return(false)
      end

      it_behaves_like 'error response', 'INVALID_USER_MEMBERSHIP'
    end

    context 'when user is eligible' do
      let(:user) { create(:user) }

      it_behaves_like 'success response'
    end

    context 'with resource locking' do
      before do
        add_on_purchase.update!(quantity: 1)
      end

      it 'prevents from double booking assignment' do
        users = create_list(:user, 3)

        expect(add_on_purchase.assigned_users.count).to eq(0)

        users.map do |user|
          Thread.new do
            described_class.new(
              add_on_purchase: add_on_purchase,
              user: user
            ).execute
          end
        end.each(&:join)

        expect(add_on_purchase.assigned_users.count).to eq(1)
      end

      context 'when NoSeatsAvailableError is raised' do
        let(:service_instance) { described_class.new(add_on_purchase: add_on_purchase, user: user) }

        subject(:response) { service_instance.execute }

        it 'handes the error correctly' do
          # fill up the available seats
          create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)

          # Mock first call to return true to pass the validate phase
          expect(service_instance).to receive(:seats_available?).and_return(true)
          expect(service_instance).to receive(:seats_available?).and_call_original

          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            an_instance_of(described_class::NoSeatsAvailableError),
            log_params.merge({ message: 'User AddOn assignment creation failed' })
          )

          expect { response }.not_to raise_error
          expect(response.errors).to include('NO_SEATS_AVAILABLE')
        end
      end
    end
  end
end
