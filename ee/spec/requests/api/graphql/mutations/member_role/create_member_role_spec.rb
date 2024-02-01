# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'creating member role', feature_category: :system_access do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:current_user) { create(:user) }

  let(:name) { 'member role name' }
  let(:permissions) { MemberRole.all_customizable_permissions.keys.map(&:to_s).map(&:upcase) }
  let(:input) do
    {
      group_path: group.path,
      base_access_level: 'GUEST',
      permissions: permissions
    }
  end

  let(:fields) do
    <<~FIELDS
      errors
      memberRole {
        id
        name
        description
        enabledPermissions {
          nodes {
            value
          }
        }
      }
    FIELDS
  end

  let(:mutation) { graphql_mutation(:member_role_create, input, fields) }

  subject(:create_member_role) { graphql_mutation_response(:member_role_create) }

  shared_examples 'a mutation that creates a member role' do
    it 'returns success', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to be_nil

      expect(create_member_role['memberRole']['enabledPermissions']['nodes'].flat_map(&:values))
        .to match_array(permissions)
    end

    it 'creates the member role', :aggregate_failures do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { MemberRole.count }.by(1)

      member_role = MemberRole.last

      expect(member_role.read_vulnerability).to eq(true)

      expect(member_role.namespace).to eq(group)
    end
  end

  context 'without the custom roles feature' do
    before do
      stub_licensed_features(custom_roles: false)
    end

    context 'with owner role' do
      before_all do
        group.add_owner(current_user)
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end
  end

  # to make this spec passing add a new argument to the mutation
  # when implementing a new custom role permission
  context 'with the custom roles feature' do
    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'when creating a group level member role' do
      context 'with maintainer role' do
        before_all do
          group.add_maintainer(current_user)
        end

        it_behaves_like 'a mutation that returns a top-level access error'
      end

      context 'with owner role' do
        before_all do
          group.add_owner(current_user)
        end

        context 'when on self-managed' do
          context 'when restrict_member_roles feature-flag is disabled' do
            before do
              stub_feature_flags(restrict_member_roles: false)
            end

            it_behaves_like 'a mutation that creates a member role'
          end

          context 'when restrict_member_roles feature-flag is enabled' do
            before do
              stub_feature_flags(restrict_member_roles: true)
            end

            it_behaves_like 'a mutation that returns a top-level access error'
          end
        end

        context 'when on SaaS', :saas do
          context 'with valid arguments' do
            it_behaves_like 'a mutation that creates a member role'
          end

          context 'with an array of permissions' do
            let(:permissions) { ['READ_VULNERABILITY'] }

            it_behaves_like 'a mutation that creates a member role'
          end

          context 'with an unknown permission' do
            let(:permissions) { ['read_unknown'] }

            it 'returns an error' do
              post_graphql_mutation(mutation, current_user: current_user)

              expect(graphql_errors).to be_present
            end
          end

          context 'with missing arguments' do
            let(:input) { { group_path: group.path } }

            it_behaves_like 'an invalid argument to the mutation', argument_name: 'baseAccessLevel'
          end
        end
      end
    end

    context 'when creating an instance level member role' do
      let(:input) do
        {
          base_access_level: 'GUEST',
          permissions: permissions
        }
      end

      context 'with unauthorized user' do
        it_behaves_like 'a mutation that returns a top-level access error'
      end

      context 'with admin', :enable_admin_mode do
        before do
          current_user.update!(admin: true)
        end

        context 'when on self-managed' do
          it 'returns success', :aggregate_failures do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(graphql_errors).to be_nil

            expect(create_member_role['memberRole']['enabledPermissions']['nodes'].flat_map(&:values))
              .to match_array(permissions)
          end

          it 'creates the member role', :aggregate_failures do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .to change { MemberRole.count }.by(1)

            member_role = MemberRole.last

            expect(member_role.read_vulnerability).to eq(true)

            expect(member_role.namespace).to be_nil
          end
        end

        context 'when on SaaS', :saas do
          before do
            stub_feature_flags(restrict_member_roles: false)
          end

          it_behaves_like 'a mutation that returns top-level errors', errors: ['group_path argument is required.']
        end
      end
    end
  end
end
