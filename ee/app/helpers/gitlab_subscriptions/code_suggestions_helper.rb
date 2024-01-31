# frozen_string_literal: true

module GitlabSubscriptions
  module CodeSuggestionsHelper
    include GitlabSubscriptions::SubscriptionHelper

    def code_suggestions_available?(namespace = nil)
      if gitlab_com_subscription?
        Feature.enabled?(:hamilton_seat_management, namespace)
      else
        Feature.enabled?(:self_managed_code_suggestions)
      end
    end

    def add_duo_pro_seats_url(subscription_name)
      return unless code_suggestions_available?

      ::Gitlab::Routing.url_helpers.subscription_portal_add_duo_pro_seats_url(subscription_name)
    end
  end
end
