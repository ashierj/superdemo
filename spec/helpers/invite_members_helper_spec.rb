# frozen_string_literal: true

require "spec_helper"

RSpec.describe InviteMembersHelper do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }

  let(:owner) { project.owner }

  before do
    helper.extend(Gitlab::Experimentation::ControllerConcern)
  end

  describe '#common_invite_modal_dataset' do
    context 'when member_areas_of_focus is enabled', :experiment do
      context 'with control experience' do
        before do
          stub_experiments(member_areas_of_focus: :control)
        end

        it 'has expected attributes' do
          attributes = {
            areas_of_focus_options: [],
            no_selection_areas_of_focus: []
          }

          expect(helper.common_invite_modal_dataset(project)).to include(attributes)
        end
      end

      context 'with candidate experience' do
        before do
          stub_experiments(member_areas_of_focus: :candidate)
        end

        it 'has expected attributes', :aggregate_failures do
          output = helper.common_invite_modal_dataset(project)

          expect(output[:no_selection_areas_of_focus]).to eq ['no_selection']
          expect(Gitlab::Json.parse(output[:areas_of_focus_options]).first['value']).to eq 'Contribute to the codebase'
        end
      end
    end

    context 'when member_areas_of_focus is disabled' do
      before do
        stub_feature_flags(member_areas_of_focus: false)
      end

      it 'has expected attributes' do
        attributes = {
          id: project.id,
          name: project.name,
          default_access_level: Gitlab::Access::GUEST,
          areas_of_focus_options: [],
          no_selection_areas_of_focus: []
        }

        expect(helper.common_invite_modal_dataset(project)).to match(attributes)
      end
    end
  end

  context 'with project' do
    before do
      allow(helper).to receive(:current_user) { owner }
      assign(:project, project)
    end

    describe "#can_invite_members_for_project?" do
      context 'when the user can_manage_project_members' do
        before do
          allow(helper).to receive(:can_manage_project_members?).and_return(true)
        end

        it 'returns true' do
          expect(helper.can_invite_members_for_project?(project)).to eq true
          expect(helper).to have_received(:can_manage_project_members?)
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(invite_members_group_modal: false)
          end

          it 'returns false' do
            expect(helper.can_invite_members_for_project?(project)).to eq false
            expect(helper).not_to have_received(:can_manage_project_members?)
          end
        end
      end

      context 'when the user can not manage project members' do
        before do
          expect(helper).to receive(:can_manage_project_members?).and_return(false)
        end

        it 'returns false' do
          expect(helper.can_invite_members_for_project?(project)).to eq false
        end
      end
    end

    describe "#directly_invite_members?" do
      context 'when the user is an owner' do
        before do
          allow(helper).to receive(:current_user) { owner }
        end

        it 'returns true' do
          expect(helper.directly_invite_members?).to eq true
        end
      end

      context 'when the user is a developer' do
        before do
          allow(helper).to receive(:current_user) { developer }
        end

        it 'returns false' do
          expect(helper.directly_invite_members?).to eq false
        end
      end
    end
  end

  context 'with group' do
    let_it_be(:group) { create(:group) }

    describe "#invite_group_members?" do
      context 'when the user is an owner' do
        before do
          group.add_owner(owner)
          allow(helper).to receive(:current_user) { owner }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_empty_group_version_a) { false }

          expect(helper.invite_group_members?(group)).to eq false
        end

        it 'returns true' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_empty_group_version_a) { true }

          expect(helper.invite_group_members?(group)).to eq true
        end
      end

      context 'when the user is a developer' do
        before do
          group.add_developer(developer)
          allow(helper).to receive(:current_user) { developer }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_empty_group_version_a) { true }

          expect(helper.invite_group_members?(group)).to eq false
        end
      end
    end
  end
end
