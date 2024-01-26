# frozen_string_literal: true

module GitlabSubscriptions
  module SubscriptionHelper
    def gitlab_com_subscription?
      ::Gitlab::Saas.feature_available?(:gitlab_com_subscriptions)
    end
  end
end
