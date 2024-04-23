# frozen_string_literal: true

module EE
  module Members
    module ImportProjectTeamService
      extend ::Gitlab::Utils::Override

      override :check_seats!
      def check_seats!
        root_namespace = target_project.root_ancestor
        invited_user_ids = source_project.project_members.pluck_user_ids

        return unless root_namespace.block_seat_overages? && !root_namespace.seats_available_for?(invited_user_ids)

        raise ::Members::ImportProjectTeamService::SeatLimitExceededError, error_message
      end

      private

      def error_message
        messages = [
          s_('AddMember|There are not enough available seats to invite this many users.')
        ]

        unless can?(current_user, :owner_access, target_project.root_ancestor)
          messages << s_('AddMember|Ask a user with the Owner role to purchase more seats.')
        end

        messages.join(" ")
      end
    end
  end
end
