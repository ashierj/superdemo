# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLinks::DestroyService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:project) { create(:project_empty_repo, :private) }
    let_it_be(:user) { create(:user) }
    let_it_be(:source) { create(:work_item, project: project) }
    let_it_be(:linked_item) { create(:work_item, project: project) }

    let_it_be(:link) { create(:work_item_link, source: source, target: linked_item) }

    let(:extra_params) { {} }
    let(:ids_to_remove) { [linked_item.id] }

    subject(:destroy_links) do
      described_class.new(source, user, { item_ids: ids_to_remove, extra_params: extra_params }).execute
    end

    before_all do
      project.add_guest(user)
    end

    context 'when synced_work_item: true' do
      let(:extra_params) { { synced_work_item: true } }

      it 'does not create a system note' do
        expect(SystemNoteService).not_to receive(:unrelate_issuable)

        expect { destroy_links }.not_to change { SystemNoteMetadata.count }
      end
    end

    context 'when there is an epic for the work item' do
      let_it_be(:group) { create(:group) }
      let_it_be(:epic_a) { create(:epic, :with_synced_work_item, group: group) }
      let_it_be(:epic_b) { create(:epic, :with_synced_work_item, group: group) }
      let_it_be(:source) { epic_a.work_item }
      let_it_be(:target) { epic_b.work_item }
      let_it_be(:link) { create(:work_item_link, source: source, target: target) }

      let_it_be(:ids_to_remove) { [target.id] }

      before_all do
        group.add_guest(user)
      end

      context 'when synced_work_item: true' do
        let(:extra_params) { { synced_work_item: true } }

        it 'skips the permission check' do
          expect { destroy_links }.to change { WorkItems::RelatedWorkItemLink.count }.by(-1)
        end
      end

      context 'when synced_work_item is not set' do
        it 'skips does not destroy the links' do
          expect { destroy_links }.to not_change { WorkItems::RelatedWorkItemLink.count }
        end
      end
    end

    context 'when synced_work_item: false' do
      it 'creates system notes' do
        expect(SystemNoteService).to receive(:unrelate_issuable).with(source, linked_item, user)
        expect(SystemNoteService).to receive(:unrelate_issuable).with(linked_item, source, user)

        destroy_links
      end
    end
  end
end
