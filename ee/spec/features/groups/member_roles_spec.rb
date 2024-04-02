# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Member Roles', :js, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:name) { 'My custom role' }
  let(:description) { 'My role description' }
  let(:permissions) { { read_vulnerability: { name: 'read_vulnerability' } } }
  let(:permission) { :read_vulnerability }
  let(:permission_name) { permission.to_s.humanize }
  let(:access_level) { 'Developer' }

  before_all do
    group.add_owner(user)
  end

  before do
    stub_licensed_features(custom_roles: true)
  end

  def create_role(access_level, name, description, permissions)
    click_button 'New role'
    select access_level, from: 'Base role'
    fill_in 'Name', with: name
    fill_in 'Description', with: description
    permissions.each do |permission|
      page.check permission
    end
    click_button 'Create role'
  end

  def created_role(id, name, description, access_level, permissions)
    [id, name, description, access_level, *permissions].join(' ')
  end

  describe 'adding a new custom role' do
    before do
      allow(Gitlab::CustomRoles::Definition).to receive(:all).and_return(permissions)

      sign_in(user)
    end

    shared_examples 'creates a new custom role' do
      it 'and displays it' do
        create_role(access_level, name, description, [permission_name])

        created_member_role = MemberRole.permissions_where(permission => true)
          .find_by(name: name, base_access_level: Gitlab::Access.options[access_level])

        expect(created_member_role).not_to be_nil

        role = created_role(created_member_role.id, name, description, access_level, [permission_name])
        expect(page).to have_content(role)
      end
    end

    context 'when on SaaS' do
      before do
        stub_saas_features(gitlab_com_subscriptions: true)

        visit group_settings_roles_and_permissions_path(group)
      end

      it_behaves_like 'creates a new custom role'
    end

    context 'when on self-managed' do
      before do
        stub_saas_features(gitlab_com_subscriptions: false)
      end

      context 'when restrict_member_roles feature-flag is disabled' do
        before do
          stub_feature_flags(restrict_member_roles: false)

          visit group_settings_roles_and_permissions_path(group)
        end

        it_behaves_like 'creates a new custom role'
      end

      context 'when restrict_member_roles feature-flag is enabled' do
        before do
          stub_feature_flags(restrict_member_roles: true)

          visit group_settings_roles_and_permissions_path(group)
        end

        it 'shows an error message' do
          create_role(access_level, name, description, [permission_name])

          expect(page).to have_content('Failed to create role')
        end
      end
    end
  end
end
