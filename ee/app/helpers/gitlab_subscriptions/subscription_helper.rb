# frozen_string_literal: true

module GitlabSubscriptions
  module SubscriptionHelper
    def gitlab_saas?
      ::Gitlab::Saas.feature_available?(:gitlab_saas_subscriptions)
    end

    def gitlab_sm?
      !gitlab_saas?
    end
  end
end
