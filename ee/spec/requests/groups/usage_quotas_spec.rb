# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view usage quotas', feature_category: :consumables_cost_management do
  describe 'GET /groups/:group/-/usage_quotas' do
    subject(:request) { get group_usage_quotas_path(namespace) }

    let_it_be(:namespace) { create(:group) }
    let_it_be(:user) { create(:user) }

    before_all do
      namespace.add_owner(user)
    end

    before do
      login_as(user)
    end

    context 'when storage size is over limit' do
      it_behaves_like 'namespace storage limit alert'
    end

    context 'with enable_add_on_users_filtering enabled' do
      it 'exposes the feature flags' do
        request

        expect(response.body).to have_pushed_frontend_feature_flags(enableAddOnUsersFiltering: true)
      end
    end

    context 'with enable_add_on_users_filtering disabled' do
      before do
        stub_feature_flags(enable_add_on_users_filtering: false)
      end

      it 'does not expose feature flags' do
        request

        expect(response.body).not_to have_pushed_frontend_feature_flags(enableAddOnUsersFiltering: true)
      end
    end

    context 'with enable_bulk_add_on_assignment enabled' do
      before do
        stub_feature_flags(enable_bulk_add_on_assignment: namespace)
      end

      it 'exposes the feature flag' do
        request

        expect(response.body).to have_pushed_frontend_feature_flags(enableBulkAddOnAssignment: true)
      end

      it 'does not expose the feature flag' do
        get group_usage_quotas_path(create(:group))

        expect(response.body).not_to have_pushed_frontend_feature_flags(enableBulkAddOnAssignment: true)
      end
    end

    context 'with enable_bulk_add_on_assignment disabled' do
      before do
        stub_feature_flags(enable_bulk_add_on_assignment: false)
      end

      it 'does not expose feature flag' do
        request

        expect(response.body).not_to have_pushed_frontend_feature_flags(enableBulkAddOnAssignment: true)
      end
    end
  end
end
