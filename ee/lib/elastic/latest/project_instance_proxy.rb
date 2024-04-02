# frozen_string_literal: true

module Elastic
  module Latest
    class ProjectInstanceProxy < ApplicationInstanceProxy
      SCHEMA_VERSION = 24_02

      TRACKED_FEATURE_SETTINGS = %w[
        issues_access_level
        merge_requests_access_level
        snippets_access_level
        wiki_access_level
        repository_access_level
      ].freeze

      def as_indexed_json(_options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        data = {}

        [
          :id,
          :name,
          :path,
          :description,
          :namespace_id,
          :created_at,
          :updated_at,
          :archived,
          :visibility_level,
          :last_activity_at,
          :name_with_namespace,
          :path_with_namespace
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        # ES6 is now single-type per index, so we implement our own typing
        data['type'] = 'project'

        # Schema version. The format is Date.today.strftime('%y_%m')
        # Please update if you're changing the schema of the document
        data['schema_version'] = SCHEMA_VERSION

        data['traversal_ids'] = target.elastic_namespace_ancestry

        if ::Elastic::DataMigrationService.migration_has_finished?(:add_ci_catalog_to_project)
          data['ci_catalog'] = target.catalog_resource.present?
        end

        if ::Elastic::DataMigrationService.migration_has_finished?(:add_fields_to_projects_index)
          data['mirror'] = target.mirror?
          data['forked'] = target.forked? || false
          data['owner_id'] = target.owner&.id
          data['repository_languages'] = target.repository_languages.map(&:name)
        end

        data.merge!(add_count_fields(target))

        unless ::Elastic::DataMigrationService.migration_has_finished?(:migrate_projects_to_separate_index)
          # Set it as a parent in our `project => child` JOIN field
          data['join_field'] = es_type
          TRACKED_FEATURE_SETTINGS.each do |feature|
            data[feature] = if target.project_feature.present?
                              target.project_feature.public_send(feature) # rubocop:disable GitlabSecurity/PublicSend
                            else
                              logger.warn(message: 'Project is missing ProjectFeature', id: target.id)
                              ProjectFeature::PRIVATE
                            end
          end
        end

        data
      end

      def es_parent
        return unless ::Elastic::DataMigrationService.migration_has_finished?(:migrate_projects_to_separate_index)

        "n_#{target.root_ancestor.id}"
      end

      private

      def add_count_fields(target)
        data = {}
        if ::Elastic::DataMigrationService.migration_has_finished?(:add_count_fields_to_projects)
          data['star_count'] = target.star_count
          data['last_repository_updated_date'] = target.last_repository_updated_at
        end

        data
      end
    end
  end
end
