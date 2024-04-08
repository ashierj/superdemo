# frozen_string_literal: true

# TODO: to be removed at 17.0
module WorkItems
  module RolledupDates
    class UpdateParentRolledupDatesEventHandler
      include Gitlab::EventStore::Subscriber

      data_consistency :always
      feature_category :portfolio_management
      idempotent!

      def handle_event(event); end
    end
  end
end
