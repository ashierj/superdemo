# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLink do
  describe '#destroy' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let!(:project_group_link) { create(:project_group_link, project: project, group: group) }

    before do
      project.add_developer(user)
    end

    shared_examples_for 'deleted related access levels' do |access_level_class|
      it "removes related #{access_level_class}" do
        expect { project_group_link.destroy! }.to change(access_level_class, :count).by(-1)
        expect(access_levels.find_by_group_id(group)).to be_nil
        expect(access_levels.find_by_user_id(user)).to be_persisted
      end
    end

    context 'protected tags' do
      let!(:protected_tag) do
        ProtectedTags::CreateService.new(
          project,
          project.first_owner,
          attributes_for(
            :protected_tag,
            create_access_levels_attributes: [{ group_id: group.id }, { user_id: user.id }]
          )
        ).execute
      end

      let(:access_levels) { protected_tag.create_access_levels }

      it_behaves_like 'deleted related access levels', ProtectedTag::CreateAccessLevel
    end

    context 'protected environments' do
      let!(:protected_environment) do
        ProtectedEnvironments::CreateService.new(
          container: project,
          current_user: project.first_owner,
          params: attributes_for(
            :protected_environment,
            deploy_access_levels_attributes: [{ group_id: group.id }, { user_id: user.id }]
          )
        ).execute
      end

      let(:access_levels) { protected_environment.deploy_access_levels }

      it_behaves_like 'deleted related access levels', ProtectedEnvironment::DeployAccessLevel

      context 'with approval rules' do
        let(:access_levels) { protected_environment.approval_rules }

        before do
          create(:protected_environment_approval_rule, protected_environment: protected_environment, group: group)
          create(:protected_environment_approval_rule, protected_environment: protected_environment, user: user)
        end

        it_behaves_like 'deleted related access levels', ::ProtectedEnvironments::ApprovalRule
      end
    end
  end

  describe '#group_with_allowed_email_domains' do
    let(:shared_project) { create(:project, group: shared_project_group) }

    subject do
      build(:project_group_link, project: shared_project, group: shared_with_group)
    end

    shared_examples 'restricted membership by email domain' do
      context 'shared project group has membership restricted by allowed email domains' do
        before do
          create(:allowed_email_domain, group: shared_project_group.root_ancestor, domain: 'gitlab.com')
          create(:allowed_email_domain, group: shared_project_group.root_ancestor, domain: 'gitlab.cn')
        end

        context 'shared with group with a subset of allowed email domains' do
          before do
            create(:allowed_email_domain, group: shared_with_group.root_ancestor, domain: 'gitlab.com')
          end

          it { is_expected.to be_valid }
        end

        context 'shared with group containing domains outside the shared group allowed email domains' do
          before do
            create(:allowed_email_domain, group: shared_with_group.root_ancestor, domain: 'example.com')
          end

          it { is_expected.to be_invalid }
        end

        context 'shared with group does not have membership restricted by allowed domains' do
          it { is_expected.to be_invalid }
        end
      end

      context 'shared project group does not have membership restricted by allowed domains' do
        context 'shared with group has membership restricted by allowed email domains' do
          before do
            create(:allowed_email_domain, group: shared_with_group.root_ancestor, domain: 'example.com')
          end

          it { is_expected.to be_valid }
        end

        context 'shared with group does not have membership restricted by allowed domains' do
          it { is_expected.to be_valid }
        end
      end
    end

    context 'shared project group is the root ancestor' do
      let_it_be(:shared_project_group) { create(:group) }
      let_it_be(:shared_with_group) { create(:group) }

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared project group is a subgroup' do
      let_it_be(:shared_project_group) { create(:group, parent: create(:group)) }
      let_it_be(:shared_with_group) { create(:group) }

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared with group is a subgroup' do
      let_it_be(:shared_project_group) { create(:group) }
      let_it_be(:shared_with_group) { create(:group, parent: create(:group)) }

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared project group and shared with group are subgroups' do
      let_it_be(:shared_project_group) { create(:group, parent: create(:group)) }
      let_it_be(:shared_with_group) { create(:group, parent: create(:group)) }

      it_behaves_like 'restricted membership by email domain'
    end
  end
end
