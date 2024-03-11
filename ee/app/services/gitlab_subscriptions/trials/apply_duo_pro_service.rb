# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class ApplyDuoProService < ::GitlabSubscriptions::Trials::BaseApplyTrialService
      def valid_to_generate_trial?
        # TODO: Add additional eligibility checks
        # https://gitlab.com/gitlab-org/gitlab/-/issues/448506
        namespace.present?
      end

      private

      def execute_trial_request
        client.generate_addon_trial(uid: uid, trial_user: trial_user_information)
      end
    end
  end
end
