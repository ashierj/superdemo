# frozen_string_literal: true

module GitlabSubscriptions
  module CodeSuggestionsHelper
    include GitlabSubscriptions::SubscriptionHelper

    def code_suggestions_available?(namespace = nil)
      if gitlab_saas?
        Feature.enabled?(:hamilton_seat_management, namespace)
      else
        Feature.enabled?(:self_managed_code_suggestions) && License.current&.paid?
      end
    end
  end
end
