# frozen_string_literal: true

module EE
  module UserPreference
    extend ActiveSupport::Concern

    prepended do
      validates :roadmap_epics_state, allow_nil: true, inclusion: {
        in: ::Epic.state_ids.values, message: "%{value} is not a valid epic state id"
      }

      validates :epic_notes_filter, inclusion: { in: ::UserPreference::NOTES_FILTERS.values }, presence: true

      delegate :code_suggestions_enabled?, :code_suggestions, :code_suggestions=, to: :user
    end
  end
end
