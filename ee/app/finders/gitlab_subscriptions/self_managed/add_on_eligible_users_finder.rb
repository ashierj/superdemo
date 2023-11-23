# frozen_string_literal: true

module GitlabSubscriptions
  module SelfManaged
    class AddOnEligibleUsersFinder
      attr_reader :add_on_type, :search_term

      def initialize(add_on_type:, search_term: nil)
        @add_on_type = add_on_type
        @search_term = search_term
      end

      def execute
        return ::User.none unless add_on_type == :code_suggestions

        users = ::User.active.without_bots.without_ghosts

        users = users.search(search_term) if search_term

        users
      end
    end
  end
end
