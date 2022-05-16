# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportScheduleWorker do
  let!(:project) { create(:project) }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let!(:import_state) { create(:import_state, :none, project: project) }

      let(:job_args) { [project.id] }

      before do
        allow(Gitlab::Mirror).to receive(:available_capacity).and_return(5)
        allow(Gitlab::Mirror).to receive(:untrack_scheduling).and_call_original

        allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
        allow(project).to receive(:add_import_job)
      end

      it 'does nothing if the database is read-only' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        expect(ProjectImportState).not_to receive(:project_id).with(project_id: project.id)

        subject
      end

      it 'schedules an import for a project' do
        expect(project).to receive(:add_import_job)
        expect(import_state).to be_none

        subject

        expect(import_state).to be_scheduled
      end

      it 'tracks the status of the worker' do
        subject

        expect(Gitlab::Mirror).to have_received(:untrack_scheduling).with(project.id).at_least(:once)
      end
    end

    context 'project is not found' do
      it 'does not fail' do
        expect { subject.perform(-1) }.not_to raise_error
      end

      it 'logs the error' do
        expect(subject).to receive(:log_extra_metadata_on_done)
          .with(:mirroring_skipped, 'No import state found for -1').and_call_original

        subject.perform(-1)
      end
    end

    context 'project does not have import state' do
      it 'does not fail' do
        expect(project.import_state).to be_nil

        expect { subject.perform(project.id) }.not_to raise_error
      end

      it 'logs the error' do
        expect(subject).to receive(:log_extra_metadata_on_done)
          .with(:mirroring_skipped, "No import state found for #{project.id}").and_call_original

        subject.perform(project.id)
      end
    end
  end
end
