# frozen_string_literal: true

require 'zlib'
require 'archive/tar/minitar'

module Import
  class ArchiveFileTypeValidator
    include Gitlab::Utils::StrongMemoize

    ServiceError = Class.new(StandardError)

    def initialize(archive_path:)
      @archive_path = archive_path
    end

    def valid?
      strong_memoize(:valid) do # rubocop:disable Gitlab/StrongMemoizeAttr
        validate
      end
    end

    private

    def validate
      valid_archive = true

      validate_archive_typeflag

      valid_archive
    rescue StandardError => e
      log_error(e.message)

      false
    end

    def validate_archive_typeflag
      File.open(@archive_path, 'rb') do |file|
        gzip_reader = Zlib::GzipReader.new(file)
        Archive::Tar::Minitar::Input.open(gzip_reader) do |input|
          input.each_entry do |entry|
            # a unix integer value of 6 means the file is a FIFO/pipe file.
            raise(ServiceError, 'Archive file type FIFO is not valid') if entry.typeflag == '6'
          end
        end
      end
    end

    def log_error(error)
      Gitlab::Import::Logger.info(
        message: error,
        import_upload_archive_path: @archive_path
      )
    end
  end
end
