# frozen_string_literal: true

module WorkItems
  module Widgets
    module ColorService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return delete_color if work_item.color.present? && new_type_excludes_widget?

          return unless params.present? && params.key?(:color)
          return unless has_permission?(:admin_work_item)

          color = work_item.color || work_item.build_color

          color.color = params[:color]

          raise WidgetError, color.errors.full_messages.join(', ') unless color.save

          create_notes if color.saved_change_to_attribute?(:color)

          work_item.touch
        end

        private

        def delete_color
          work_item.color.destroy!

          create_notes

          work_item.touch
        end

        def create_notes
          ::SystemNoteService.change_color_note(work_item, current_user)
        end
      end
    end
  end
end
