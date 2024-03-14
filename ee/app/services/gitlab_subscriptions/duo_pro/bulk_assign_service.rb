# frozen_string_literal: true

module GitlabSubscriptions
  module DuoPro
    class BulkAssignService < BaseService
      include Gitlab::Utils::StrongMemoize
      ERROR_NOT_ENOUGH_SEATS = 'NOT_ENOUGH_SEATS'
      ERROR_INVALID_USER_ID_PRESENT = 'INVALID_USER_ID_PRESENT'

      NotEnoughSeatsError = Class.new(StandardError)

      def initialize(add_on_purchase:, user_ids:)
        @add_on_purchase = add_on_purchase
        @user_ids = user_ids.to_set
      end

      def execute
        ineligible_user_ids = user_ids - eligible_user_ids
        return invalid_user_id_present if ineligible_user_ids.any?

        ensure_seat_availability

        upsert_data = eligible_user_ids.map { |user_id| { user_id: user_id } }

        add_on_purchase.with_lock do
          ensure_seat_availability

          add_on_purchase.assigned_users.upsert_all(
            upsert_data,
            unique_by: %i[add_on_purchase_id user_id]
          )
        end

        Gitlab::AppLogger.info(log_events(type: 'success',
          payload: { users: eligible_user_ids }))
        ServiceResponse.success(payload: { users: User.id_in(eligible_user_ids) })

      rescue NotEnoughSeatsError
        not_enough_seats
      end

      private

      attr_reader :add_on_purchase, :user_ids

      def invalid_user_id_present
        Gitlab::AppLogger.error(log_events(type: 'not_eligible_users',
          payload: { errors: ERROR_INVALID_USER_ID_PRESENT, user_ids: user_ids }))
        ServiceResponse.error(message: ERROR_INVALID_USER_ID_PRESENT)
      end

      def not_enough_seats
        Gitlab::AppLogger.error(log_events(type: 'error', payload: { errors: ERROR_NOT_ENOUGH_SEATS }))
        ServiceResponse.error(message: ERROR_NOT_ENOUGH_SEATS)
      end

      def ensure_seat_availability
        raise NotEnoughSeatsError unless seats_available?
      end

      def seats_available?
        add_on_purchase.quantity >= (assigned_seats + eligible_user_ids.count)
      end

      def assigned_seats
        add_on_purchase.assigned_users.count
      end

      def eligible_user_ids
        namespace.gitlab_duo_pro_eligible_user_ids & user_ids
      end
      strong_memoize_attr :eligible_user_ids

      def namespace
        @namespace ||= add_on_purchase.namespace
      end

      def log_events(type:, payload:)
        {
          add_on_purchase_id: add_on_purchase.id,
          message: 'Duo Pro Bulk User Assignment',
          response_type: type,
          payload: payload
        }
      end
    end
  end
end
