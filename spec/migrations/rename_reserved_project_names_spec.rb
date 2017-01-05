# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20161221153951_rename_reserved_project_names.rb')

# This migration uses multiple threads, and thus different transactions. This
# means data created in this spec may not be visible to some threads. To work
# around this we use the TRUNCATE cleaning strategy.
describe RenameReservedProjectNames, truncate: true do
  let(:migration) { described_class.new }
  let!(:project) { create(:empty_project) }

  before do
    project.path = 'projects'
    project.save!(validate: false)
  end

  describe '#up' do
    context 'when project repository exists' do
      before { project.create_repository }

      context 'when no exception is raised' do
        it 'renames project with reserved names' do
          migration.up

          expect(project.reload.path).to eq('projects0')
        end
      end

      context 'when exception is raised during rename' do
        before do
          allow(project).to receive(:rename_repo).and_raise(StandardError)
        end

        it 'captures exception from project rename' do
          expect { migration.up }.not_to raise_error
        end
      end
    end

    context 'when project repository does not exist' do
      it 'does not raise error' do
        expect { migration.up }.not_to raise_error
      end
    end
  end
end
