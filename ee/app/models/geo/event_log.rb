# frozen_string_literal: true

module Geo
  class EventLog < ApplicationRecord
    include IgnorableColumns

    ignore_column :geo_event_id_convert_to_bigint, remove_with: '16.11', remove_after: '2024-03-21'

    ignore_columns %i[
      hashed_storage_migrated_event_id
      hashed_storage_attachments_event_id
      repository_created_event_id
      repository_updated_event_id
      repository_deleted_event_id
      repository_renamed_event_id
      reset_checksum_event_id
    ], remove_with: '17.0', remove_after: '2024-05-16'

    include Geo::Model
    include ::EachBatch

    EVENT_CLASSES = %w[Geo::CacheInvalidationEvent
                       Geo::RepositoriesChangedEvent
                       Geo::Event].freeze

    belongs_to :cache_invalidation_event,
      class_name: 'Geo::CacheInvalidationEvent',
      foreign_key: :cache_invalidation_event_id

    belongs_to :repositories_changed_event,
      class_name: 'Geo::RepositoriesChangedEvent',
      foreign_key: :repositories_changed_event_id

    belongs_to :geo_event,
      class_name: 'Geo::Event',
      foreign_key: :geo_event_id,
      inverse_of: :geo_event_log

    def self.latest_event
      order(id: :desc).first
    end

    def self.next_unprocessed_event
      last_processed = Geo::EventLogState.last_processed
      return first unless last_processed

      find_by('id > ?', last_processed.event_id)
    end

    def self.event_classes
      EVENT_CLASSES.map(&:constantize)
    end

    def self.includes_events
      includes(reflections.keys)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def event
      repositories_changed_event ||
        cache_invalidation_event ||
        geo_event
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def project_id
      event.try(:project_id)
    end
  end
end
