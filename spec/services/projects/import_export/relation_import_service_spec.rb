# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'returns failure response' do |expected_status|
  it 'returns an error status' do
    response = import_service.execute

    expect(response).to be_instance_of(ServiceResponse)
    expect(response).not_to be_success
    expect(response.http_status).to eq(expected_status)
  end
end

RSpec.describe ::Projects::ImportExport::RelationImportService, :aggregate_failures, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:params) do
    {
      path: project_path,
      file: fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz', 'application/gzip'),
      relation: relation
    }
  end

  let(:relation) { 'issues' }

  let_it_be(:user) { create(:user) }

  subject(:import_service) { described_class.new(current_user: user, params: params) }

  describe '#execute' do
    context 'when the project exists' do
      let(:project_path) { project.full_path }

      context 'and the user is a maintainer' do
        before_all do
          project.add_maintainer(user)
        end

        it 'schedules a restore of the relation' do
          expect(Projects::ImportExport::RelationImportWorker).to receive(:perform_async)

          import_service.execute
        end

        it 'returns a service response' do
          response = import_service.execute

          expect(response).to be_instance_of(ServiceResponse)
          expect(response).to be_success
          expect(response.http_status).to eq(:ok)
          expect(response.payload).to be_instance_of(Projects::ImportExport::RelationImportTracker)
        end
      end

      context 'and the user has developer access' do
        before_all do
          project.add_developer(user)
        end

        include_examples 'returns failure response', :forbidden
      end

      context 'and the has no access' do
        include_examples 'returns failure response', :forbidden
      end

      context 'and the user triggers an import before the last one finishes' do
        before_all do
          project.add_maintainer(user)
        end

        before do
          project.relation_import_trackers.create!(relation: 'issues', status: 1)
        end

        include_examples 'returns failure response', :conflict
      end

      context 'and an invalid relation is passed' do
        let(:relation) { 'invalid_relation' }

        include_examples 'returns failure response', :bad_request
      end
    end

    context 'when the project does not exist' do
      let(:project_path) { 'some/unknown/project' }

      include_examples 'returns failure response', :not_found
    end
  end
end
