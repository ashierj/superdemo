# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group).tap { |group| group.add_developer(developer) } }
  let_it_be(:work_item_type) { create(:work_item_type, :epic, namespace: group) }

  let(:current_user) { developer }
  let(:extra_params) { {} }
  let(:widget_params) { {} }
  let(:params) do
    {
      work_item_type: work_item_type,
      title: 'Awesome work_item',
      description: 'please fix',
      confidential: true
    }
  end

  describe '#execute' do
    let(:service) do
      described_class.new(
        container: group,
        current_user: current_user,
        params: params.merge(extra_params),
        widget_params: widget_params
      )
    end

    subject(:create_work_item) { service.execute }

    before do
      stub_licensed_features(epics: true)
    end

    context 'when params are valid' do
      it 'created instance is a WorkItem' do
        expect(Issuable::CommonSystemNotesService).to receive_message_chain(:new, :execute)

        work_item = create_work_item[:work_item]

        expect(work_item).to be_persisted
        expect(work_item).to be_a(::WorkItem)
        expect(work_item.title).to eq('Awesome work_item')
        expect(work_item.description).to eq('please fix')
        expect(work_item.confidential).to eq(true)
        expect(work_item.work_item_type.base_type).to eq('epic')
      end

      it 'calls NewIssueWorker with correct arguments' do
        expect(NewIssueWorker).to receive(:perform_async)
          .with(Integer, current_user.id, 'WorkItem')

        create_work_item
      end

      context 'when synced_work_item is true' do
        let(:extra_params) { { extra_params: { synced_work_item: true } } }

        it 'does not call system notes service' do
          expect(Issuable::CommonSystemNotesService).not_to receive(:new)

          work_item = create_work_item[:work_item]

          expect(work_item).to be_persisted
          expect(work_item).to be_a(::WorkItem)
        end

        it 'does not call after commit workers' do
          expect(NewIssueWorker).not_to receive(:perform_async)
          expect(Issues::PlacementWorker).not_to receive(:perform_async)
          expect(Onboarding::IssueCreatedWorker).not_to receive(:perform_async)

          create_work_item
        end
      end
    end
  end
end
