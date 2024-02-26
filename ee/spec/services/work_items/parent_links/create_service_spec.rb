# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group).tap { |g| g.add_reporter(user) } }
    let_it_be(:work_item1) { create(:work_item, :epic, namespace: group) }
    let_it_be(:work_item2) { create(:work_item, :epic, namespace: group) }
    let_it_be(:with_synced_epic) { create(:epic, :with_synced_work_item, group: group).work_item }

    let(:params) { { issuable_references: [child_work_item] } }

    subject(:create_link) { described_class.new(parent_work_item, user, params).execute }

    shared_examples 'does not create relationship' do
      it 'no relationship is created' do
        expect { create_link }.not_to change { WorkItems::ParentLink.count }
      end

      it 'returns error' do
        is_expected.to eq({
          http_status: 404,
          status: :error,
          message: 'No matching work item found. Make sure that you are adding a valid work item ID.'
        })
      end
    end

    context "when work items don't have a synced epic" do
      let_it_be(:parent_work_item) { work_item1 }
      let_it_be(:child_work_item) { work_item2 }

      it 'relationship is created' do
        expect { create_link }.to change { WorkItems::ParentLink.count }.by(1)
      end
    end

    context 'when parent work item has a synced epic' do
      let_it_be(:parent_work_item) { with_synced_epic }
      let_it_be(:child_work_item) { work_item2 }

      it_behaves_like 'does not create relationship'

      context 'when synced_work_item param is true' do
        let(:params) { { issuable_references: [child_work_item], synced_work_item: true } }

        it 'relationship is created' do
          expect { create_link }.to change { WorkItems::ParentLink.count }.by(1)
        end
      end
    end

    context 'when child work item has a synced epic' do
      let_it_be(:parent_work_item) { work_item1 }
      let_it_be(:child_work_item) { with_synced_epic }

      it_behaves_like 'does not create relationship'

      context 'when synced_work_item param is true' do
        let(:params) { { issuable_references: [child_work_item], synced_work_item: true } }

        it 'relationship is created' do
          expect { create_link }.to change { WorkItems::ParentLink.count }.by(1)
        end
      end
    end

    context 'when work items have a synced epic' do
      let_it_be(:parent_work_item) { with_synced_epic }
      let_it_be(:child_work_item) { create(:epic, :with_synced_work_item, group: group).work_item }

      it_behaves_like 'does not create relationship'

      context 'when synced_work_item param is true' do
        let(:params) { { issuable_references: [child_work_item], synced_work_item: true } }

        it 'relationship is created' do
          expect { create_link }.to change { WorkItems::ParentLink.count }.by(1)
        end
      end
    end
  end
end
