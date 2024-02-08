# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationPolicy, feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:current_user) { create(:user) }

  subject(:policy) { described_class.new(current_user, organization) }

  context 'when the user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      context 'when dependency scanning is enabled' do
        before do
          stub_licensed_features(dependency_scanning: true)
        end

        it { is_expected.to be_allowed(:read_dependency) }
      end

      context 'when dependency scanning is disabled' do
        before do
          stub_licensed_features(dependency_scanning: false)
        end

        it { is_expected.to be_disallowed(:read_dependency) }
      end

      context 'when license scanning is enabled' do
        before do
          stub_licensed_features(license_scanning: true)
        end

        it { is_expected.to be_allowed(:read_licenses) }
      end

      context 'when license scanning is disabled' do
        before do
          stub_licensed_features(license_scanning: false)
        end

        it { is_expected.to be_disallowed(:read_licenses) }
      end
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(:read_dependency) }
      it { is_expected.to be_disallowed(:read_licenses) }
    end
  end
end
