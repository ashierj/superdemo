# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class CreateService < BaseCreateService
      private

      def lead_service_class
        GitlabSubscriptions::CreateLeadService
      end

      def apply_trial_service_class
        GitlabSubscriptions::Trials::ApplyTrialService
      end

      def namespaces_eligible_for_trial
        user.manageable_namespaces_eligible_for_trial
      end
    end
  end
end
