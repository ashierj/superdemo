# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Standards::ExportService, feature_category: :compliance_management do
  subject(:service) { described_class.new user: user, group: group }

  let_it_be(:user) { create(:user, name: 'Foo Bar') }
  let_it_be(:group) { create(:group, name: 'parent') }

  let_it_be(:csv_header) do
    "Status,Project ID,Check,Standard,Last Scanned"
  end

  let_it_be(:project) do
    create :project, :repository, namespace: group, name: 'Parent Project', path: 'parent_project'
  end

  describe '#execute' do
    context 'without visibility to user' do
      it { expect(service.execute).to be_error }

      it 'exports a CSV payload with just the header' do
        expect(service.execute.message).to eq "Access to group denied for user with ID: #{user.id}"
      end
    end

    context 'with a authorized user' do
      before_all do
        group.add_owner(user)
      end

      context 'with no standards adherences' do
        it 'exports a CSV payload without standards adherences' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).to eq "#{csv_header}\n"
        end
      end

      context 'with a standards adherence' do
        let_it_be(:adherence) { create(:compliance_standards_adherence, project: project) }

        it 'exports a CSV payload' do
          expected_row = "success,#{project.id},prevent_approval_by_merge_request_author,gitlab,#{adherence.updated_at}"

          export = <<~EXPORT
          #{csv_header}
          #{expected_row}
          EXPORT

          expect(service.execute.payload).to eq export
        end

        it "avoids N+1 when exporting" do
          service.execute # warm up cache

          build :compliance_standards_adherence

          control = ActiveRecord::QueryRecorder.new(query_recorder_debug: true) { service.execute }

          build :compliance_standards_adherence

          expect { service.execute }.not_to exceed_query_limit(control)
        end
      end
    end
  end

  describe '#email_export' do
    let(:worker) { ComplianceManagement::StandardsAdherenceExportMailerWorker }

    context "with compliance_standards_adherence_csv_export ff implicitly enabled" do
      it 'enqueues a worker' do
        expect(worker).to receive(:perform_async).with(user.id, group.id)

        expect(service.email_export).to be_success
      end
    end

    context "with compliance_standards_adherence_csv_export ff disabled" do
      it 'skips enqueue of a worker' do
        stub_feature_flags compliance_standards_adherence_csv_export: false

        expect(worker).not_to receive(:perform_async)

        expect(service.email_export).to be_success
      end
    end
  end
end
