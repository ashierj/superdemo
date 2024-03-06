# frozen_string_literal: true

# EE:SaaS
module Subscriptions
  module Trials
    class DuoProController < ApplicationController
      include OneTrustCSP
      include GoogleAnalyticsCSP
      include RegistrationsTracking
      include ::Gitlab::Utils::StrongMemoize

      layout 'minimal'

      skip_before_action :set_confirm_warning
      before_action :check_feature_available!
      before_action :authenticate_user!

      feature_category :purchase
      urgency :low

      def new
        if params[:step] == GitlabSubscriptions::Trials::CreateService::TRIAL
          track_event('render_duo_pro_trial_page')

          render :step_namespace
        else
          track_event('render_duo_pro_lead_page')

          render :step_lead
        end
      end

      def create
        # TODO: Implement actual duo pro trial activation and move all the logic
        # to separate service
        # https://gitlab.com/gitlab-org/gitlab/-/issues/435875
        case params[:step]
        when GitlabSubscriptions::Trials::CreateService::LEAD
          lead_flow
        when GitlabSubscriptions::Trials::CreateService::TRIAL
          trial_flow
        end

        redirect_to new_trials_duo_pro_path(
          namespace_id: params[:namespace_id],
          step: GitlabSubscriptions::Trials::CreateService::TRIAL
        )
      end

      private

      def lead_flow
        if true # rubocop: disable Lint/LiteralAsCondition -- Implement actual duo pro lead
          track_event('duo_pro_lead_creation_success')
        else
          track_event('duo_pro_lead_creation_failure')
        end
      end

      def trial_flow
        if true # rubocop: disable Lint/LiteralAsCondition -- Implement actual duo pro trial
          track_event('duo_pro_trial_registration_success')
        else
          track_event('duo_pro_trial_registration_failure')
        end
      end

      def authenticate_user!
        return if current_user

        redirect_to new_trial_registration_path(glm_tracking_params), alert: I18n.t('devise.failure.unauthenticated')
      end

      def check_feature_available!
        if Feature.enabled?(:duo_pro_trials, current_user, type: :wip) &&
            ::Gitlab::Saas.feature_available?(:subscriptions_trials)
          return
        end

        render_404
      end

      def namespace
        current_user.manageable_namespaces_eligible_for_trial.find_by_id(params[:namespace_id])
      end
      strong_memoize_attr :namespace

      def track_event(action)
        Gitlab::InternalEvents.track_event(action, user: current_user, namespace: namespace)
      end
    end
  end
end
