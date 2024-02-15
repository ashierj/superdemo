# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateService, feature_category: :team_planning do
  RSpec.shared_examples 'creates work item in container' do |container_type|
    include_context 'with container for work items service', container_type

    describe '#execute' do
      subject(:service_result) { service.execute }

      before do
        stub_licensed_features(epics: true, epic_colors: true)
      end

      context 'when user is not allowed to create a work item in the container' do
        let(:current_user) { user_with_no_access }

        it { is_expected.to be_error }

        it 'returns an access error' do
          expect(service_result.errors).to contain_exactly('Operation not allowed')
        end
      end

      context 'when params are valid' do
        let(:type) { WorkItems::Type.default_by_type(:task) }
        let(:opts) { { title: 'Awesome work_item', description: 'please fix', work_item_type: type } }

        it 'created instance is a WorkItem' do
          expect(Issuable::CommonSystemNotesService).to receive_message_chain(:new, :execute)

          work_item = service_result[:work_item]

          expect(work_item).to be_persisted
          expect(work_item).to be_a(::WorkItem)
          expect(work_item.title).to eq('Awesome work_item')
          expect(work_item.description).to eq('please fix')
          expect(work_item.work_item_type.base_type).to eq('task')
        end

        it 'calls NewIssueWorker with correct arguments' do
          expect(NewIssueWorker).to receive(:perform_async)
                                      .with(Integer, current_user.id, 'WorkItem')

          service_result
        end

        context 'when synced_work_item is true' do
          let(:extra_params) { { extra_params: { synced_work_item: true } } }

          it 'does not call system notes service' do
            expect(Issuable::CommonSystemNotesService).not_to receive(:new)

            work_item = service_result[:work_item]

            expect(work_item).to be_persisted
            expect(work_item).to be_a(::WorkItem)
          end

          it 'does not call after commit workers' do
            expect(NewIssueWorker).not_to receive(:perform_async)
            expect(Issues::PlacementWorker).not_to receive(:perform_async)
            expect(Onboarding::IssueCreatedWorker).not_to receive(:perform_async)

            service_result
          end
        end

        describe 'with color widget params' do
          let(:widget_params) { { color_widget: { color: '#c91c00' } } }

          before do
            skip 'these examples only apply to a group container' unless container.is_a?(Group)
          end

          context 'when user can admin_work_item' do
            let(:current_user) { reporter }

            context 'when type does not support color widget' do
              it 'creates new work item without setting color' do
                expect { service_result }.to change { WorkItem.count }.by(1).and(
                  not_change { WorkItems::Color.count }
                )
                expect(service_result[:work_item].color).to be_nil
                expect(service_result[:status]).to be(:success)
              end
            end

            context 'when type supports color widget' do
              let(:type) { WorkItems::Type.default_by_type(:epic) }

              it 'creates new work item and sets color' do
                expect { service_result }.to change { WorkItem.count }.by(1).and(
                  change { WorkItems::Color.count }.by(1)
                )
                expect(service_result[:work_item].color.color.to_s).to eq('#c91c00')
                expect(service_result[:status]).to be(:success)
              end
            end
          end
        end
      end
    end
  end

  it_behaves_like 'creates work item in container', :project
  it_behaves_like 'creates work item in container', :project_namespace
  it_behaves_like 'creates work item in container', :group
end
