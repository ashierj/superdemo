# frozen_string_literal: true

module EE
  module Gitlab
    module Saas
      extend ActiveSupport::Concern

      MissingFeatureError = Class.new(StandardError)

      FEATURES = %w[purchases/additional_minutes onboarding].freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :feature_available?
        def feature_available?(feature)
          raise MissingFeatureError, 'Feature does not exist' unless FEATURES.include?(feature)

          enabled?
        end

        def enabled?
          # Use existing checks initially. We can allow it only in this place and remove it anywhere else.
          # eventually we can change its implementation like using an ENV variable for each instance
          # or any other method that people can't mess with.
          ::Gitlab.com?
        end
      end
    end
  end
end
