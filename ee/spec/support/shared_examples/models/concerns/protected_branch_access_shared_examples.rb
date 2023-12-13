# frozen_string_literal: true

RSpec.shared_examples 'ee protected branch access' do
  describe '#check_access' do
    let_it_be(:user_project) { create(:project, :empty_repo) }
    let(:protected_ref) { create(:protected_branch, project: project) }
    let_it_be(:current_user) { create(:user) }
    let(:project) { user_project }

    let(:access_level) { nil }
    let(:user) { nil }
    let(:group) { create(:group) }

    before_all do
      user_project.add_maintainer(current_user)
    end

    subject do
      described_class.new(
        protected_branch: protected_ref,
        user: user,
        group: group,
        access_level: access_level
      )
    end

    context 'when the group is not invited' do
      it { expect(subject.check_access(current_user)).to eq(false) }

      context 'when group has no access to project' do
        context 'and the user is a developer in the group ' do
          before do
            group.add_developer(current_user)
          end

          it { expect(subject.check_access(current_user)).to eq(false) }
        end
      end
    end

    context 'when group is invited' do
      let!(:project_group_link) do
        create :project_group_link, invited_group_access_level, project: project, group: group
      end

      context 'and the group has max role less than developer' do
        let(:invited_group_access_level) { :reporter }

        context 'and the user is a developer in the group ' do
          before do
            group.add_developer(current_user)
          end

          it { expect(subject.check_access(current_user)).to eq(false) }
        end
      end

      context 'and the group has max role of at least developer' do
        let(:invited_group_access_level) { :developer }

        context 'when current_user is a developer the group' do
          before do
            group.add_developer(current_user)
          end

          it { expect(subject.check_access(current_user)).to eq(true) }
        end

        context 'when current_user is a guest in the group' do
          before do
            group.add_guest(current_user)
          end

          it { expect(subject.check_access(current_user)).to eq(false) }
        end

        context 'when current_user is not in the group' do
          it { expect(subject.check_access(current_user)).to eq(false) }
        end

        context 'when current_user is a member of another group that has access to group' do
          using RSpec::Parameterized::TableSyntax
          let(:group_group_link) do
            create(:group_group_link, other_group_access_level, shared_group: project_group_link.group)
          end

          let(:other_group) { group_group_link.shared_with_group }

          context 'when current user has develop access to the other group' do
            where(:invited_group_access_level, :other_group_access_level, :expected_access) do
              :developer | :developer | false
              :developer | :guest     | false
              :guest     | :guest     | false
              :guest     | :developer | false
            end

            before do
              other_group.add_developer(current_user)
            end

            with_them do
              it { expect(subject.check_access(current_user)).to eq(expected_access) }
            end
          end

          context 'when current user has guest access to the other group' do
            where(:invited_group_access_level, :other_group_access_level, :expected_access) do
              :developer | :developer | false
              :developer | :guest     | false
              :guest     | :guest     | false
              :guest     | :developer | false
            end

            before do
              other_group.add_guest(current_user)
            end

            with_them do
              it { expect(subject.check_access(current_user)).to eq(expected_access) }
            end
          end
        end
      end

      context 'when group is a subgroup' do
        let(:subgroup) { create(:group, :nested) }
        let(:parent_group) { subgroup.parent }
        let(:parent_group_developer) { create(:user) }
        let(:parent_group_guest) { create(:user) }
        let(:invited_group_access_level) { :developer }
        let(:group) { subgroup }

        before do
          parent_group.add_developer(parent_group_developer)
          parent_group.add_guest(parent_group_guest)
        end

        context 'when user is a developer of the parent group' do
          it { expect(subject.check_access(parent_group_developer)).to eq(false) }
        end

        context 'when user is a guest of the parent group' do
          it { expect(subject.check_access(parent_group_guest)).to eq(false) }
        end
      end
    end
  end
end
