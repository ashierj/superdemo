# frozen_string_literal: true

module WorkItems
  module Widgets
    module RolledupDatesService
      class CreateService < BaseService
        def after_create_in_transaction(params: {})
          handle_rolledup_dates_change(params)
        end
      end
    end
  end
end
