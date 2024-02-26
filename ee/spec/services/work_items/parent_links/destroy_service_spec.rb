# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::DestroyService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group).tap { |g| g.add_reporter(user) } }
    let_it_be(:work_item1) { create(:work_item, :epic, namespace: group) }
    let_it_be(:work_item2) { create(:work_item, :epic, namespace: group) }
    let_it_be(:with_synced_epic1) { create(:epic, :with_synced_work_item, group: group).work_item }
    let_it_be(:with_synced_epic2) { create(:epic, :with_synced_work_item, group: group).work_item }

    let(:params) { {} }

    subject(:destroy_link) { described_class.new(parent_link, user, params).execute }

    shared_examples 'does not remove relationship' do
      it 'does not remove relation', :aggregate_failures do
        expect { destroy_link }.to not_change { WorkItems::ParentLink.count }.from(1)
          .and not_change { WorkItems::ResourceLinkEvent.count }
        expect(SystemNoteService).not_to receive(:unrelate_work_item)
      end

      it 'returns error message' do
        is_expected.to eq(message: 'No Work Item Link found', status: :error, http_status: 404)
      end
    end

    context "when work items doesn't have a synced epic" do
      let_it_be(:parent_link) { create(:parent_link, work_item: work_item1, work_item_parent: work_item2) }

      it 'removes relation', :aggregate_failures do
        expect { destroy_link }.to change { WorkItems::ParentLink.count }.by(-1)
      end
    end

    context "when parent work item has a synced epic" do
      let_it_be(:parent_link) { create(:parent_link, work_item: with_synced_epic1, work_item_parent: work_item1) }

      it_behaves_like 'does not remove relationship'

      context 'when synced_work_item param is true' do
        let(:params) { { synced_work_item: true } }

        it 'removed relationship' do
          expect { destroy_link }.to change { WorkItems::ParentLink.count }.by(-1)
        end
      end
    end

    context 'when child work item has a synced epic' do
      let_it_be(:parent_link) { create(:parent_link, work_item: work_item1, work_item_parent: with_synced_epic1) }

      it_behaves_like 'does not remove relationship'

      context 'when synced_work_item param is true' do
        let(:params) { { synced_work_item: true } }

        it 'removed relationship' do
          expect { destroy_link }.to change { WorkItems::ParentLink.count }.by(-1)
        end
      end
    end

    context 'when work items have a synced epic' do
      let_it_be(:parent_link) do
        create(:parent_link, work_item: with_synced_epic1, work_item_parent: with_synced_epic2)
      end

      it_behaves_like 'does not remove relationship'

      context 'when synced_work_item param is true' do
        let(:params) { { synced_work_item: true } }

        it 'removed relationship' do
          expect { destroy_link }.to change { WorkItems::ParentLink.count }.by(-1)
        end
      end
    end
  end
end
