# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance-level Member Roles', :js, feature_category: :permissions do
  let_it_be(:admin) { create(:admin) }

  let(:name) { 'My custom role' }
  let(:permissions) { { read_vulnerability: { name: 'read_vulnerability' } } }
  let(:permission) { :read_vulnerability }
  let(:permission_name) { permission.to_s.humanize }
  let(:access_level) { 'Developer' }

  before_all do
    sign_in(admin)
  end

  before do
    stub_licensed_features(custom_roles: true)
  end

  def create_role(access_level, name, permissions)
    click_button 'Add new role'
    select access_level, from: 'Base role to use as template'
    fill_in 'Role name', with: name
    permissions.each do |permission|
      page.check permission
    end
    click_button 'Create new role'
  end

  def created_role(name, id, access_level, permissions)
    [name, id, access_level, *permissions].join(' ')
  end

  describe 'adding a new custom role', :enable_admin_mode do
    before do
      allow(Gitlab::CustomRoles::Definition).to receive(:all).and_return(permissions)

      visit admin_application_settings_roles_and_permissions_path
    end

    it 'creates a new custom role' do
      create_role(access_level, name, [permission_name])

      created_member_role = MemberRole.find_by(
        name: name,
        base_access_level: Gitlab::Access.options[access_level],
        permission => true)

      expect(created_member_role).not_to be_nil

      role = created_role(name, created_member_role.id, access_level, [permission_name])
      expect(page).to have_content(role)
    end
  end
end
