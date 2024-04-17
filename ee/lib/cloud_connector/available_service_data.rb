# frozen_string_literal: true

# Presents a service enabled through Cloud Connector
module CloudConnector
  class AvailableServiceData
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
      add_ons_assigned_to(user).any?
    end

    def access_token
      ::CloudConnector::ServiceAccessToken.active.last&.token
    end

    private

    def add_ons_assigned_to(user)
      cache_key = format(GitlabSubscriptions::UserAddOnAssignment::USER_ADD_ON_ASSIGNMENT_CACHE_KEY, user_id: user.id)

      Rails.cache.fetch(cache_key) do
        GitlabSubscriptions::AddOnPurchase.assigned_to_user(user).by_add_on_name(@add_on_names)
      end
    end
  end
end
