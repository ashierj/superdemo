# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchRulePolicy, feature_category: :source_code_management do
  let_it_be(:name) { 'feature' }
  let_it_be(:protected_branch) { create(:protected_branch, name: name) }
  let_it_be(:project) { protected_branch.project }
  let_it_be(:allowed_group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }

  subject { described_class.new(user, branch_rule) }

  before_all do
    project.add_maintainer(user)
    project.project_group_links.create!(group: allowed_group)
  end

  context 'when an unprotect access level for a group is configured' do
    before_all do
      protected_branch.unprotect_access_levels.create!(group: allowed_group)
    end

    context 'and unprotection restriction feature is unlicensed' do
      it_behaves_like 'allows branch rule crud'
    end

    context 'and unprotection restriction feature is licensed' do
      before do
        stub_licensed_features(unprotection_restrictions: true)
      end

      it { is_expected.to be_allowed(:read_branch_rule) }

      it_behaves_like 'disallows branch rule changes'

      context 'and the user is a member of the group' do
        before_all do
          allowed_group.add_guest(user)
        end

        it_behaves_like 'allows branch rule crud'
      end
    end
  end
end
