# frozen_string_literal: true

# EE:SaaS
module Subscriptions
  module Trials
    class DuoProController < ApplicationController
      include RegistrationsTracking

      layout 'minimal'

      skip_before_action :set_confirm_warning
      before_action :check_feature_available!
      before_action :authenticate_user!

      feature_category :purchase
      urgency :low

      def new
        if params[:step] == GitlabSubscriptions::Trials::CreateService::TRIAL
          render :step_namespace
        else
          render :step_lead
        end
      end

      def create
        # TODO: Implement actual duo pro trial activation
        # https://gitlab.com/gitlab-org/gitlab/-/issues/435875
        redirect_to new_trials_duo_pro_path(
          namespace_id: params[:namespace_id],
          step: GitlabSubscriptions::Trials::CreateService::TRIAL
        )
      end

      private

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
    end
  end
end
