# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Color < ::WorkItems::Callbacks::Base
      ALLOWED_PARAMS = %i[color skip_system_notes].freeze

      def after_initialize
        return work_item.color.destroy! if work_item.color.present? && excluded_in_new_type?

        handle_color_change if params.key?(:color) && has_permission?(:admin_work_item)
      end

      def after_save_commit
        ::SystemNoteService.change_color_note(work_item, current_user, @previous_color) if create_system_notes?
      end

      private

      def handle_color_change
        @previous_color = work_item&.color&.color&.to_s
        color = work_item.color || work_item.build_color
        return if params[:color] == color.color.to_s

        color.color = params[:color]
        raise_error(color.errors.full_messages.join(', ')) unless color.save
      end

      def create_system_notes?
        return false if params.fetch(:skip_system_notes, false) || work_item.color.nil?

        work_item.color.destroyed? || work_item.color.previous_changes.include?('color')
      end
    end
  end
end
