# frozen_string_literal: true

module Dependencies
  module ExportSerializers
    class OrganizationDependenciesService
      def initialize(export)
        @export = export
      end

      def filename
        "#{export.organization.to_param}_dependencies_#{Time.current.utc.strftime('%FT%H%M')}.csv"
      end

      def each
        yield header

        iterator.each_batch do |batch|
          build_list_for(batch).each do |occurrence|
            yield to_csv([
              occurrence.component_name,
              occurrence.version,
              occurrence.package_manager,
              occurrence.location[:blob_path]
            ])
          end
        end
      end

      private

      attr_reader :export

      def header
        to_csv(%w[Name Version Packager Location])
      end

      def iterator
        if export.organization.owner?(export.author) || export.author.can_read_all_resources?
          Gitlab::Pagination::Keyset::Iterator
            .new(scope: export.organization.sbom_occurrences)
        else
          clazz = ::Sbom::Occurrence
          # rubocop: disable CodeReuse/ActiveRecord -- where clause
          Gitlab::Pagination::Keyset::Iterator.new(
            scope: export.organization.sbom_occurrences.order(:id),
            in_operator_optimization_options: {
              array_scope: export.author.project_authorizations.select(:project_id),
              array_mapping_scope: ->(id) { clazz.where(clazz.arel_table[:project_id].eq(id)) },
              finder_query: ->(id) { clazz.where(clazz.arel_table[:id].eq(id)) }
            }
          )
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end

      def build_list_for(batch)
        batch
          .with_source
          .with_version
          .with_project_namespace
      end

      def to_csv(row)
        CSV.generate_line(row, force_quotes: true)
      end
    end
  end
end
