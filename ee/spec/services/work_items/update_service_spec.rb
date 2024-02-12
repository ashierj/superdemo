# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group).tap { |proj| proj.add_developer(developer) } }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:current_user) { developer }
  let(:params) { {} }

  describe '#execute' do
    let(:service) do
      described_class.new(
        container: project,
        current_user: current_user,
        params: params,
        widget_params: widget_params
      )
    end

    subject(:update_work_item) { service.execute(work_item) }

    it_behaves_like 'work item widgetable service' do
      let(:widget_params) do
        {
          weight_widget: { weight: 1 }
        }
      end

      let(:service_execute) { subject }

      let(:supported_widgets) do
        [
          {
            klass: WorkItems::Widgets::WeightService::UpdateService,
            callback: :before_update_callback, params: { weight: 1 }
          }
        ]
      end
    end

    context 'when updating widgets' do
      context 'for the progress widget' do
        let(:widget_params) { { progress_widget: { progress: 50 } } }

        before do
          stub_licensed_features(okrs: true)
        end

        it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
          subject(:execute_service) { update_work_item }
        end
      end

      context 'for the weight widget' do
        let(:widget_params) { { weight_widget: { weight: new_weight } } }

        before do
          stub_licensed_features(issue_weights: true)

          work_item.update!(weight: 1)
        end

        context 'when weight is changed' do
          let(:new_weight) { nil }

          it "triggers 'issuableWeightUpdated' for issuable weight update subscription" do
            expect(GraphqlTriggers).to receive(:issuable_weight_updated).with(work_item).and_call_original

            subject
          end

          it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
            subject(:execute_service) { update_work_item }
          end
        end

        context 'when weight remains unchanged' do
          let(:new_weight) { 1 }

          it "does not trigger 'issuableWeightUpdated' for issuable weight update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_weight_updated)

            subject
          end
        end

        context 'when weight widget param is not provided' do
          let(:widget_params) { {} }

          it "does not trigger 'issuableWeightUpdated' for issuable weight update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_weight_updated)

            subject
          end
        end
      end

      context 'for the iteration widget' do
        let_it_be(:cadence) { create(:iterations_cadence, group: group) }
        let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }

        let(:widget_params) { { iteration_widget: { iteration: new_iteration } } }

        before do
          stub_licensed_features(iterations: true)

          work_item.update!(iteration: nil)
        end

        context 'when iteration is changed' do
          let(:new_iteration) { iteration }

          it "triggers 'issuableIterationUpdated' for issuable iteration update subscription" do
            expect(GraphqlTriggers).to receive(:issuable_iteration_updated).with(work_item).and_call_original

            subject
          end
        end

        context 'when iteration remains unchanged' do
          let(:new_iteration) { nil }

          it "does not trigger 'issuableIterationUpdated' for issuable iteration update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_iteration_updated)

            subject
          end
        end

        context 'when iteration widget param is not provided' do
          let(:widget_params) { {} }

          it "does not trigger 'issuableIterationUpdated' for issuable iteration update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_iteration_updated)

            subject
          end
        end
      end

      context 'for the health_status widget' do
        let(:widget_params) { { health_status_widget: { health_status: new_health_status } } }

        before do
          stub_licensed_features(issuable_health_status: true)

          work_item.update!(health_status: :needs_attention)
        end

        context 'when health_status is changed' do
          let(:new_health_status) { :on_track }

          it "triggers 'issuableHealthStatusUpdated' subscription" do
            expect(GraphqlTriggers).to receive(:issuable_health_status_updated).with(work_item).and_call_original

            subject
          end
        end

        context 'when health_status remains unchanged' do
          let(:new_health_status) { :needs_attention }

          it "does not trigger 'issuableHealthStatusUpdated' subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_health_status_updated)

            subject
          end
        end

        context 'when health_status widget param is not provided' do
          let(:widget_params) { {} }

          it "does not trigger 'issuableHealthStatusUpdated' subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_health_status_updated)

            subject
          end
        end
      end

      context 'for color widget' do
        let_it_be(:work_item, refind: true) { create(:work_item, :epic, namespace: group) }
        let_it_be(:default_color) { '#1068bf' }

        let(:new_color) { '#c91c00' }

        before do
          stub_licensed_features(epic_colors: true)
        end

        context 'when work item has a color' do
          let_it_be(:existing_color) { create(:color, work_item: work_item, color: '#0052cc') }

          context 'when color changes' do
            let(:widget_params) { { color_widget: { color: new_color } } }

            it 'updates existing color' do
              expect { subject }.not_to change { WorkItems::Color.count }

              expect(work_item.color.color.to_s).to eq(new_color)
              expect(work_item.color.issue_id).to eq(work_item.id)
            end

            it 'creates system notes' do
              expect(SystemNoteService).to receive(:change_color_note)
               .with(work_item, current_user, existing_color.color.to_s)
               .and_call_original

              expect { subject }.to change { Note.count }.by(1)
              expect(work_item.notes.last.note).to eq("changed color from `#{existing_color.color}` to `#{new_color}`")
            end
          end

          context 'when color remains unchanged' do
            let(:widget_params) { {} }

            it 'does not update color' do
              expect { subject }.to not_change { WorkItems::Color.count }.and not_change { Note.count }
              expect(work_item.color.color.to_s).to eq(existing_color.color.to_s)
            end
          end

          context 'when color param is the same as the work item color' do
            let(:widget_params) { { color_widget: { color: existing_color.color.to_s } } }

            it 'does not update color' do
              expect { subject }.to not_change { WorkItems::Color.count }.and not_change { Note.count }
            end
          end

          context 'when widget is not supported in the new type' do
            let(:widget_params) { { color_widget: { color: new_color } } }

            before do
              allow_next_instance_of(WorkItems::Callbacks::Color) do |instance|
                allow(instance).to receive(:excluded_in_new_type?).and_return(true)
              end
            end

            it 'removes color' do
              expect { subject }.to change { work_item.reload.color }.from(existing_color).to(nil)
            end

            it 'creates system notes' do
              expect(SystemNoteService).to receive(:change_color_note)
                .with(work_item, current_user, nil)
                .and_call_original

              expect { subject }.to change { Note.count }.by(1)
              expect(Note.last.note).to eq("removed color `#{existing_color.color}`")
            end
          end
        end

        context 'when work item has no color' do
          let(:widget_params) { { color_widget: { color: new_color } } }

          it 'creates a new color record' do
            expect { subject }.to change { WorkItems::Color.count }.by(1)

            expect(work_item.color.color.to_s).to eq(new_color)
            expect(work_item.color.issue_id).to eq(work_item.id)
          end

          it 'creates system notes' do
            expect(SystemNoteService).to receive(:change_color_note)
              .with(work_item, current_user, nil)
              .and_call_original

            expect { subject }.to change { Note.count }.by(1)
            expect(work_item.notes.last.note).to eq("set color to `#{new_color}`")
          end
        end
      end
    end

    context 'when synced_work_item param' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:forced_time) { Time.now.iso8601 }

      let(:params) { update_params.merge(extra_params) }
      let(:extra_params) { {} }
      let(:widget_params) { {} }

      before_all do
        project.add_developer(other_user)
      end

      context 'when handling system notes' do
        let(:update_params) { { description: "new description" } }

        context 'when synced_work_item is not set' do
          it 'creates system notes' do
            expect { update_work_item }.to change { SystemNoteMetadata.count }.by(1)
          end
        end

        context 'when synced_work_item is true' do
          let(:extra_params) { { extra_params: { synced_work_item: true } } }

          it 'does not create system notes' do
            expect(Issuable::CommonSystemNotesService).not_to receive(:new)

            expect { update_work_item }.not_to change { SystemNoteMetadata.count }
          end
        end
      end

      context 'when setting updated_at and created_at' do
        let(:update_params) { { created_at: forced_time, updated_at: forced_time } }

        context 'without synced_work_item param' do
          it 'does not change updated_at and created_at' do
            expect { service.execute(work_item) }.to not_change { work_item.reload.updated_at }
              .and not_change { work_item.reload.created_at }
          end
        end

        context 'when synced_work_item: true' do
          let(:extra_params) { { extra_params: { synced_work_item: true } } }

          it 'sets updated_at and created_at params' do
            service.execute(work_item)

            expect(work_item.reload.updated_at).to eq forced_time
            expect(work_item.created_at).to eq forced_time
          end
        end
      end

      context 'when setting confidential' do
        let(:update_params) { { confidential: true } }

        context 'without synced_work_item param' do
          it 'calls the confidential issue worker and creates a system note' do
            expect(TodosDestroyer::ConfidentialIssueWorker).to receive(:perform_in)
            expect(SystemNoteService).to receive(:change_issue_confidentiality)

            service.execute(work_item)

            expect(work_item.confidential).to eq(true)
          end
        end

        context 'when synced_work_item: true' do
          let(:extra_params) { { extra_params: { synced_work_item: true } } }

          it 'does not call confidential issue worker or create a system note' do
            expect(TodosDestroyer::ConfidentialIssueWorker).not_to receive(:perform_in)
            expect(SystemNoteService).not_to receive(:change_issue_confidentiality)
            expect_no_snowplow_event

            service.execute(work_item)

            expect(work_item.confidential).to eq(true)
          end
        end
      end

      context 'when changing description' do
        let(:update_params) { { last_edited_at: forced_time, last_edited_by: other_user, description: "test" } }

        context 'without synced_work_item param', :freeze_time do
          it 'uses the last_edited_by data' do
            service.execute(work_item)

            expect(work_item.reload.last_edited_at).not_to eq(forced_time)
            expect(work_item.last_edited_by).to eq(current_user)
            expect(work_item.description).to eq("test")
          end
        end

        context 'when synced_work_item: true' do
          let(:extra_params) { { extra_params: { synced_work_item: true } } }

          it 'uses the given last_edited_at and last_edited_by data' do
            service.execute(work_item)

            expect(work_item.reload.last_edited_at).to eq(forced_time)
            expect(work_item.last_edited_by).to eq(other_user)
            expect(work_item.description).to eq("test")
          end
        end
      end
    end
  end
end
