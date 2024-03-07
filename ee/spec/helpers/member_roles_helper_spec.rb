# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRolesHelper, feature_category: :permissions do
  include ApplicationHelper

  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:source) { build_stubbed(:group) }
  let_it_be(:root_group) { source.root_ancestor }

  before do
    stub_licensed_features(custom_roles: true)
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#member_roles_data' do
    subject(:member_roles_data) { helper.member_roles_data }

    let(:expected_data) do
      {
        documentation_path: help_page_path('user/custom_roles'),
        empty_state_svg_path: start_with('/assets/illustrations/empty-state/empty-user-settings-md')
      }
    end

    it { is_expected.to match(hash_including(expected_data)) }
  end

  describe '#manage_member_roles_path' do
    subject { helper.manage_member_roles_path(source) }

    context 'when on SaaS' do
      before do
        stub_saas_features(gitlab_com_subscriptions: true)
      end

      it { is_expected.to be_nil }

      context 'as owner' do
        before do
          allow(helper).to receive(:can?).with(user, :admin_group_member, root_group).and_return(true)
        end

        it { is_expected.to eq(group_settings_roles_and_permissions_path(root_group)) }

        context 'when custom roles are not available' do
          before do
            stub_licensed_features(custom_roles: false)
          end

          it { is_expected.to be_nil }
        end
      end
    end

    context 'when in admin mode', :enable_admin_mode do
      before do
        stub_saas_features(gitlab_com_subscriptions: false)
      end

      it { is_expected.to be_nil }

      context 'as admin' do
        let_it_be(:user) { build_stubbed(:user, :admin) }

        it { is_expected.to eq(admin_application_settings_roles_and_permissions_path) }

        context 'when custom roles are not available' do
          before do
            stub_licensed_features(custom_roles: false)
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
