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
        if params[:step] == GitlabSubscriptions::Trials::CreateDuoProService::TRIAL
          track_event('render_duo_pro_trial_page')

          render :step_namespace
        else
          track_event('render_duo_pro_lead_page')

          render :step_lead
        end
      end

      def create
        @result = GitlabSubscriptions::Trials::CreateDuoProService.new(
          step: params[:step], lead_params: lead_params, trial_params: trial_params, user: current_user
        ).execute

        if @result.success?
          # lead and trial created

          track_event('duo_pro_trial_registration_success')

          redirect_to group_path(@result.payload[:namespace])
        elsif @result.reason == GitlabSubscriptions::Trials::CreateDuoProService::NO_SINGLE_NAMESPACE
          # lead created, but we now need to select namespace and then apply a trial
          redirect_to new_trials_duo_pro_path(@result.payload[:trial_selection_params])
        elsif @result.reason == GitlabSubscriptions::Trials::CreateDuoProService::NOT_FOUND
          # namespace not found/not permitted to create
          render_404
        elsif @result.reason == GitlabSubscriptions::Trials::CreateDuoProService::LEAD_FAILED
          render :step_lead_failed
        elsif @result.reason == GitlabSubscriptions::Trials::CreateDuoProService::NAMESPACE_CREATE_FAILED
          # namespace creation failed
          params[:namespace_id] = @result.payload[:namespace_id]

          render :step_namespace_failed
        else
          # trial creation failed
          track_event('duo_pro_trial_registration_failure')

          params[:namespace_id] = @result.payload[:namespace_id]

          render :trial_failed
        end
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

      def namespace
        current_user.owned_groups.find_by_id(params[:namespace_id])
      end
      strong_memoize_attr :namespace

      def track_event(action)
        Gitlab::InternalEvents.track_event(action, user: current_user, namespace: namespace)
      end

      def lead_params
        params.permit(
          :company_name, :company_size, :first_name, :last_name, :phone_number,
          :country, :state, :website_url, :glm_content, :glm_source
        ).to_h
      end

      def trial_params
        params.permit(:new_group_name, :namespace_id, :trial_entity, :glm_source, :glm_content).to_h
      end
    end
  end
end
