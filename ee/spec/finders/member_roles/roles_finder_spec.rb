# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRoles::RolesFinder, feature_category: :system_access do
  let(:params) { { parent: group } }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:member_role_instance) { create(:member_role, :instance) }
  let_it_be(:group_2_member_role) { create(:member_role, name: 'Another role') }
  let_it_be(:member_role_1) { create(:member_role, name: 'Tester', namespace: group) }
  let_it_be(:member_role_2) { create(:member_role, name: 'Manager', namespace: group) }
  let_it_be(:active_group_iterations_cadence) do
    create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations')
  end

  let(:current_user) { user }

  subject(:find_member_roles) { described_class.new(current_user, params).execute }

  context 'without permissions' do
    context 'when filtering by group' do
      it 'does not return any member roles for group' do
        expect(find_member_roles).to be_empty
      end
    end

    context 'when filtering by id' do
      let(:params) { { id: member_role_2.id } }

      it 'does not return any member roles for id' do
        expect(find_member_roles).to be_empty
      end
    end
  end

  context 'with permissions' do
    before_all do
      group.add_owner(user)
    end

    context 'without custom roles feature' do
      before do
        stub_licensed_features(custom_roles: false)
      end

      it 'does not return any member roles for group' do
        expect(find_member_roles).to be_empty
      end
    end

    context 'with custom roles feature' do
      before do
        stub_licensed_features(custom_roles: true)
      end

      context 'when filter param is missing' do
        let(:params) { {} }

        it 'raises an error' do
          expect { find_member_roles }.to raise_error(ArgumentError)
        end
      end

      context 'when filtering by group' do
        it 'returns all member roles of the group' do
          expect(find_member_roles).to eq([member_role_2, member_role_1])
        end
      end

      context 'when filtering by project' do
        let(:params) { { parent: project } }

        it 'returns all member roles of the project root ancestor' do
          expect(find_member_roles).to eq([member_role_2, member_role_1])
        end
      end

      context 'when filtering by id' do
        let(:params) { { id: member_role_2.id } }

        it 'returns member role found by id' do
          expect(find_member_roles).to eq([member_role_2])
        end
      end

      context 'when filtering by multiple ids' do
        let(:params) { { id: [member_role_1.id, member_role_2.id, group_2_member_role.id] } }

        it 'returns only member roles a user can read' do
          expect(find_member_roles).to eq([member_role_2, member_role_1])
        end

        context 'when a user is an instance admin', :enable_admin_mode do
          let(:current_user) { admin }

          it 'returns all requested member roles for the instance admin' do
            expect(find_member_roles).to eq([group_2_member_role, member_role_2, member_role_1])
          end

          context 'when providing the order_by and sort parameters' do
            using RSpec::Parameterized::TableSyntax

            let_it_be(:name_asc) { [group_2_member_role, member_role_2, member_role_1] }
            let_it_be(:name_desc) { [member_role_1, member_role_2, group_2_member_role] }
            let_it_be(:id_asc) { [group_2_member_role, member_role_1, member_role_2] }
            let_it_be(:id_desc) { [member_role_2, member_role_1, group_2_member_role] }

            where(:order, :sort, :result) do
              nil         | nil   | :name_asc
              nil         | :asc  | :name_asc
              nil         | :desc | :name_desc
              :name       | nil   | :name_asc
              :name       | :asc  | :name_asc
              :name       | :desc | :name_desc
              :id         | nil   | :id_asc
              :id         | :asc  | :id_asc
              :id         | :desc | :id_desc
              :created_at | nil   | :id_asc
              :created_at | :asc  | :id_asc
              :created_at | :desc | :id_desc
            end

            with_them do
              let(:params) { super().merge(order_by: order, sort: sort) }

              it 'returns the result with correct ordering' do
                expect(find_member_roles).to eq public_send(result)
              end
            end
          end
        end
      end

      context 'when requesting roles for the whole instance' do
        let(:params) { { instance_roles: true } }

        context 'when a user does not have permissions' do
          it 'raises an error' do
            expect { find_member_roles }.to raise_error(ArgumentError)
          end
        end

        context 'when a user is an instance admin', :enable_admin_mode do
          let(:current_user) { admin }

          context 'when on self-managed' do
            it 'returns instance member roles for instance admin' do
              expect(find_member_roles).to eq([member_role_instance])
            end
          end

          context 'when on SaaS', :saas do
            it 'returns an error' do
              expect { find_member_roles }.to raise_error(ArgumentError)
            end
          end
        end
      end

      context 'when requesting an instance roles by id' do
        let(:params) { { id: member_role_instance.id } }

        context 'when a user does not have permissions' do
          it 'returns an empty array' do
            expect(find_member_roles).to be_empty
          end
        end

        context 'when a user is an instance admin', :enable_admin_mode do
          let(:current_user) { admin }

          context 'when on self-managed' do
            it 'returns instance member roles for instance admin' do
              expect(find_member_roles).to eq([member_role_instance])
            end
          end

          context 'when on SaaS', :saas do
            it 'returns an empty array' do
              expect(find_member_roles).to be_empty
            end
          end
        end
      end

      context 'when requesting roles for the whole instance and group' do
        let(:params) { { instance_roles: true, parent: group } }

        context 'when a user is an instance admin', :enable_admin_mode do
          let(:current_user) { admin }

          context 'when on self-managed' do
            it 'returns both instance member roles and group member roles' do
              expect(find_member_roles).to eq([member_role_instance, member_role_2, member_role_1])
            end
          end
        end
      end
    end
  end
end
