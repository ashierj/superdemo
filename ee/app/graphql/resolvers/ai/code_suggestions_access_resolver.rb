# frozen_string_literal: true

module Resolvers
  module Ai
    class CodeSuggestionsAccessResolver < BaseResolver
      type ::GraphQL::Types::Boolean, null: false

      def resolve
        return false unless current_user

        Feature.enabled?(:code_suggestions_tokens_api, type: :ops) && current_user.duo_pro_add_on_available?
      end
    end
  end
end
