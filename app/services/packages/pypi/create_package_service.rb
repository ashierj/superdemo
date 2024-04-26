# frozen_string_literal: true

module Packages
  module Pypi
    class CreatePackageService < ::Packages::CreatePackageService
      include ::Gitlab::Utils::StrongMemoize

      def execute
        ::Packages::Package.transaction do
          meta = Packages::Pypi::Metadatum.new(
            package: created_package,
            required_python: params[:requires_python] || '',
            metadata_version: params[:metadata_version],
            author_email: params[:author_email],
            description: params[:description],
            description_content_type: params[:description_content_type],
            summary: params[:summary],
            keywords: params[:keywords]
          )

          truncate_fields(meta)

          raise ActiveRecord::RecordInvalid, meta unless meta.valid?

          params.delete(:md5_digest) if Gitlab::FIPS.enabled?

          Packages::Pypi::Metadatum.upsert(meta.attributes)

          ::Packages::CreatePackageFileService.new(created_package, file_params).execute

          ServiceResponse.success(payload: { package: created_package })
        end
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message, reason: :invalid_parameter)
      end

      private

      def created_package
        find_or_create_package!(:pypi)
      end
      strong_memoize_attr :created_package

      def file_params
        {
          build: params[:build],
          file: params[:content],
          file_name: params[:content].original_filename,
          file_md5: params[:md5_digest],
          file_sha256: params[:sha256_digest]
        }
      end

      def truncate_fields(meta)
        return if meta.valid?

        meta.errors.select { |error| error.type == :too_long }.each do |error|
          field = error.attribute

          meta[field] = meta[field].truncate(error.options[:count])
        end
      end
    end
  end
end
