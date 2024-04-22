# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class BaseApplyTrialService
      include ::Gitlab::Utils::StrongMemoize
      GENERIC_TRIAL_ERROR = :generic_trial_error

      def self.execute(args = {})
        instance = new(**args)
        instance.execute
      end

      def initialize(uid:, trial_user_information:)
        @uid = uid
        @trial_user_information = trial_user_information
      end

      def execute
        if valid_to_generate_trial?
          generate_trial
        else
          ServiceResponse.error(message: 'Not valid to generate a trial with current information')
        end
      end

      def generate_trial
        response = execute_trial_request

        if response[:success]
          after_success_hook

          ServiceResponse.success
        else
          ServiceResponse.error(message: response.dig(:data, :errors), reason: GENERIC_TRIAL_ERROR)
        end
      end

      def valid_to_generate_trial?
        raise NoMethodError, "Subclasses must implement valid_to_generate_trial? method"
      end

      private

      attr_reader :uid, :trial_user_information

      def execute_trial_request
        raise NoMethodError, "Subclasses must implement execute_trial_request method"
      end

      def client
        Gitlab::SubscriptionPortal::Client
      end

      def namespace
        Namespace.find_by_id(trial_user_information[:namespace_id])
      end
      strong_memoize_attr :namespace

      def after_success_hook
        # overridden in subclasses
      end
    end
  end
end
