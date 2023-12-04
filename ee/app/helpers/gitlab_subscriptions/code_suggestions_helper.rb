# frozen_string_literal: true

module GitlabSubscriptions
  module CodeSuggestionsHelper
    def code_suggestions_available?(namespace = nil)
      if gitlab_saas?
        Feature.enabled?(:hamilton_seat_management, namespace)
      else
        Feature.enabled?(:self_managed_code_suggestions)
      end
    end

    private

    def gitlab_saas?
      ::Gitlab::Saas.feature_available?(:code_suggestions)
    end
  end
end
