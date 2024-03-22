# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::ProcessPackageFileWorker, type: :worker, feature_category: :package_registry do
  let_it_be(:package_file) { create(:package_file, :npm) }

  describe '#perform' do
    subject(:worker) { described_class.new }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [package_file.id] }
    end

    context 'with existing package file' do
      it 'calls the ProcessPackageFileService' do
        expect_next_instance_of(Packages::Npm::ProcessPackageFileService, package_file) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform(package_file.id)
      end
    end

    context 'with a non-existing package file' do
      it 'does not call the service' do
        expect(Packages::Npm::ProcessPackageFileService).not_to receive(:new)

        worker.perform(-1)
      end
    end

    context 'with an exception' do
      let(:exception) { StandardError.new('error') }

      before do
        allow_next_instance_of(Packages::Npm::ProcessPackageFileService, package_file) do |service|
          allow(service).to receive(:execute).and_raise(exception)
        end
      end

      it 'calls the error handling service' do
        expect(worker).to receive(:process_package_file_error).with(
          package_file: package_file,
          exception: exception
        )

        worker.perform(package_file.id)
      end
    end
  end
end
