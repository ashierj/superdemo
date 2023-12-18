# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Member Roles', :js, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:name) { 'My custom role' }
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

  describe 'adding a new custom role' do
    before do
      allow(Gitlab::CustomRoles::Definition).to receive(:all).and_return(permissions)

      sign_in(user)
      visit group_settings_roles_and_permissions_path(group)
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

    context 'when the permission has a requirement' do
      let(:permissions) do
        { admin_vulnerability: { name: 'admin_vulnerability', requirement: 'read_vulnerability' },
          read_vulnerability: { name: 'read_vulnerability' } }
      end

      let(:permission) { :admin_vulnerability }
      let(:requirement) { permissions[permission][:requirement] }
      let(:requirement_name) { requirement.to_s.humanize }

      context 'when the requirement has not been met' do
        it 'show an error message' do
          create_role(access_level, name, [permission_name])

          created_member_role = MemberRole.find_by(
            name: name,
            base_access_level: Gitlab::Access.options[access_level],
            permission => true)

          expect(created_member_role).to be_nil
          expect(page).to have_content("#{requirement_name} has to be enabled in order to enable #{permission_name}")
        end
      end

      context 'when the requirement has been met' do
        it 'creates the custom role' do
          create_role(access_level, name, [permission_name, requirement_name])

          created_member_role = MemberRole.find_by(
            name: name,
            base_access_level: Gitlab::Access.options[access_level],
            permission => true,
            requirement => true)

          expect(created_member_role).not_to be_nil

          role = created_role(name, created_member_role.id, access_level, [permission_name, requirement_name])
          expect(page).to have_content(role)
        end
      end
    end
  end
end
