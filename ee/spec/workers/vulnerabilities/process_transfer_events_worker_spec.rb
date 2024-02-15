# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ProcessTransferEventsWorker, feature_category: :vulnerability_management, type: :job do
  let_it_be(:old_group) { create(:group) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :with_vulnerability, group: group) }
  let_it_be(:other_project) { create(:project, :with_vulnerability, group: group) }
  let_it_be(:project_without_vulnerabilities) { create(:project, group: group) }

  let(:project_event) do
    ::Projects::ProjectTransferedEvent.new(data: {
      project_id: project.id,
      old_namespace_id: old_group.id,
      old_root_namespace_id: old_group.id,
      new_namespace_id: group.id,
      new_root_namespace_id: group.id
    })
  end

  let(:group_event) do
    ::Groups::GroupTransferedEvent.new(data: {
      group_id: group.id,
      old_root_namespace_id: old_group.id,
      new_root_namespace_id: group.id
    })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  context 'when the associated project has vulnerabilities' do
    before do
      project.project_setting.update!(has_vulnerabilities: true)
    end

    context 'when a project transfered event is published', :sidekiq_inline do
      let(:event) { project_event }

      context 'when update_vuln_reads_on_project_transfer_via_event is disabled' do
        before do
          stub_feature_flags(update_vuln_reads_traversal_ids_via_event: false)
        end

        it_behaves_like 'ignores the published event'
      end

      it_behaves_like 'subscribes to event'

      it 'enqueues a vulnerability reads namespace id update job for the project id' do
        expect(Vulnerabilities::UpdateNamespaceIdsOfVulnerabilityReadsWorker).to receive(:perform_bulk).with(
          [[project.id]]
        )

        use_event
      end
    end

    context 'when a group transfered event is published', :sidekiq_inline do
      let(:event) { group_event }

      context 'when update_vuln_reads_on_project_transfer_via_event is disabled' do
        before do
          stub_feature_flags(update_vuln_reads_traversal_ids_via_event: false)
        end

        it_behaves_like 'ignores the published event'
      end

      it_behaves_like 'subscribes to event'

      it 'enqueues a vulnerability reads namespace id update job for each project id belonging to the namespace id' do
        expect(Vulnerabilities::UpdateNamespaceIdsOfVulnerabilityReadsWorker).to receive(:perform_bulk).with(
          match_array([[project.id], [other_project.id]])
        )

        use_event
      end
    end
  end

  context 'when the associated project does not have vulnerabilities' do
    let(:project) { project_without_vulnerabilities }

    context 'when a project transfered event is published', :sidekiq_inline do
      let(:event) { project_event }

      it 'enqueues a vulnerability reads namespace id update job for the project id' do
        expect(Vulnerabilities::UpdateNamespaceIdsOfVulnerabilityReadsWorker).to receive(:perform_bulk).with([])

        use_event
      end
    end
  end
end
