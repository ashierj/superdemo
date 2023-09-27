# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreatorService, feature_category: :groups_and_projects do
  describe '.add_member' do
    context 'when user is a security_policy_bot' do
      let_it_be(:user) { create(:user, :security_policy_bot) }
      let_it_be(:project) { create(:project) }

      subject { described_class.add_member(project, user, :guest) }

      it 'adds a member' do
        expect { subject }.to change { Member.count }.by(1)
      end

      context 'when the user is already a member of another project' do
        let_it_be(:other_project) { create(:project) }
        let_it_be(:membership) { create(:project_member, :guest, source: other_project, user: user) }

        it 'does not add a member' do
          expect { subject }.not_to change { Member.count }
        end

        it 'adds an error message to the member' do
          expect(subject.errors.messages).to include(
            base: ['security policy bot users cannot be added to other projects']
          )
        end
      end
    end
  end
end
