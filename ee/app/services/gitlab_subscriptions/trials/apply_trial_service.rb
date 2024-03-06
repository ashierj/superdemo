# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class ApplyTrialService < BaseApplyTrialService
      def valid_to_generate_trial?
        namespace.present? && !namespace.trial?
      end

      private

      def execute_trial_request
        client.generate_trial(uid: uid, trial_user: trial_user_information)
      end

      def after_success_hook
        ::Onboarding::ProgressService.new(namespace).execute(action: :trial_started)
      end

      def namespace
        Namespace.find_by_id(trial_user_information[:namespace_id])
      end
      strong_memoize_attr :namespace
    end
  end
end
