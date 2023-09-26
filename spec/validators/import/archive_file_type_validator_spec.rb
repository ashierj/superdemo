# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::ArchiveFileTypeValidator, feature_category: :importers do
  subject { described_class.new(archive_path: filepath) }

  describe '#valid?' do
    context 'when file is not a FIFO type' do
      let(:filepath) { 'spec/fixtures/group_export.tar.gz' }

      it 'returns true' do
        expect(subject.valid?).to eq(true)
      end
    end

    context 'when file is a FIFO type' do
      let(:filepath) { 'spec/fixtures/invalid_export_file.tar.gz' }

      it 'logs error message returns false' do
        expect(Gitlab::Import::Logger)
          .to receive(:info)
          .with(
            import_upload_archive_path: filepath,
            message: 'Archive file type FIFO is not valid'
          )
        expect(subject.valid?).to eq(false)
      end
    end
  end
end
