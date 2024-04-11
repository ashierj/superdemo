# frozen_string_literal: true

# Presents a service enabled through Cloud Connector
module CloudConnector
  class AvailableServiceData
    include ::Gitlab::Utils::StrongMemoize

    attr_accessor :name, :cut_off_date

    def initialize(name, cut_off_date, add_on_names)
      @name = name
      @cut_off_date = cut_off_date
      @add_on_names = add_on_names
    end

    def free_access?
      cut_off_date.nil? || cut_off_date&.future?
    end

    def allowed_for?(user)
      cache_key = format(GitlabSubscriptions::UserAddOnAssignment::USER_ADD_ON_ASSIGNMENT_CACHE_KEY, user_id: user.id)

      Rails.cache.fetch(cache_key) do
        GitlabSubscriptions::UserAddOnAssignment.by_user(user)
          .for_active_add_on_purchases(add_on_purchases).any?
      end
    end

    def access_token
      ::CloudConnector::ServiceAccessToken.active.last&.token
    end

    private

    def add_on_purchases
      GitlabSubscriptions::AddOnPurchase.by_add_on_name(@add_on_names)
    end
    strong_memoize_attr :add_on_purchases
  end
end
