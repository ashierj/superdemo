# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance-level Member Roles', feature_category: :permissions do
  let_it_be(:admin) { create(:admin) }

  let(:name) { 'My custom role' }
  let(:description) { 'My role description' }
  let(:permissions) { { read_vulnerability: { name: 'read_vulnerability' } } }
  let(:permission) { :read_vulnerability }
  let(:permission_name) { permission.to_s.humanize }
  let(:access_level) { 'Developer' }

  before do
    stub_licensed_features(custom_roles: true)
  end

  def create_role(access_level, name, description, permissions)
    click_button 'New role'
    select access_level, from: 'Base role to use as template'
    fill_in 'Role name', with: name
    fill_in 'Description', with: description
    permissions.each do |permission|
      page.check permission
    end
    click_button 'Create role'
  end

  def created_role(id, name, description, access_level, permissions)
    [id, name, description, access_level, *permissions].join(' ')
  end

  describe 'adding a new custom role', :enable_admin_mode do
    before do
      allow(Gitlab::CustomRoles::Definition).to receive(:all).and_return(permissions)

      gitlab_sign_in(admin)
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

    context 'when on self-managed', :js do
      before do
        stub_saas_features(gitlab_com_subscriptions: false)

        visit admin_application_settings_roles_and_permissions_path
      end

      it_behaves_like 'creates a new custom role'
    end

    context 'when on SaaS' do
      before do
        stub_saas_features(gitlab_com_subscriptions: true)
      end

      it 'renders 404' do
        visit admin_application_settings_roles_and_permissions_path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
