# frozen_string_literal: true

module Gitlab
  module EpicWorkItemSync
    class Diff
      BASE_ATTRIBUTES = %w[
        author_id
        closed_at
        closed_by_id
        confidential
        created_at
        description
        external_key
        iid
        last_edited_at
        last_edited_by_id
        lock_version
        state_id
        title
        updated_by_id
      ].freeze

      ALLOWED_TIME_RANGE_S = 1.second

      def initialize(epic, work_item)
        @epic = epic
        @work_item = work_item
        @mismatched_attributes = []
      end

      def attributes
        check_base_attributes
        check_updated_at
        check_namespace
        check_color

        mismatched_attributes
      end

      private

      def check_base_attributes
        BASE_ATTRIBUTES.each do |attribute|
          next if epic.attributes[attribute] == work_item.attributes[attribute]

          mismatched_attributes.push(attribute)
        end
      end

      def check_updated_at
        return if (epic.updated_at - work_item.updated_at).abs < ALLOWED_TIME_RANGE_S

        mismatched_attributes.push("updated_at")
      end

      def check_namespace
        mismatched_attributes.push("namespace") if epic.group_id != work_item.namespace_id
      end

      def check_color
        return if epic.color == Epic::DEFAULT_COLOR && work_item.color.nil?
        return if epic.color == work_item.color&.color

        mismatched_attributes.push("color")
      end

      attr_reader :epic, :work_item
      attr_accessor :mismatched_attributes
    end
  end
end
