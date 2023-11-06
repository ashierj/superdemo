# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    REACHED_LIMIT_VARIANT = 'reached'
    CLOSE_TO_LIMIT_VARIANT = 'close'

    def self.dashboard_limit
      ::Gitlab::CurrentSettings.dashboard_limit
    end

    def self.dashboard_limit_enabled?
      ::Gitlab::CurrentSettings.dashboard_limit_enabled?
    end

    def self.over_user_limit_email_enabled?(group)
      ::Feature.enabled?(:free_user_cap_over_limit_email, group)
    end

    def self.owner_access?(user:, namespace:)
      return false unless user

      Ability.allowed?(user, :owner_access, namespace)
    end

    def self.non_owner_access?(user:, namespace:)
      return false unless user
      return false if owner_access?(user: user, namespace: namespace)

      Ability.allowed?(user, :read_group, namespace)
    end
  end
end

Namespaces::FreeUserCap.prepend_mod
