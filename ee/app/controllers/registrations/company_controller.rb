# frozen_string_literal: true

module Registrations
  class CompanyController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include GoogleSyndicationCSP
    include RegistrationsTracking
    include ::Onboarding::SetRedirect

    layout 'minimal'

    before_action :verify_onboarding_enabled!
    before_action :authenticate_user!
    feature_category :onboarding

    helper_method :onboarding_status

    def new
      track_event('render')
    end

    def create
      result = GitlabSubscriptions::CreateCompanyLeadService.new(user: current_user, params: service_params).execute

      if result.success?
        track_event('successfully_submitted_form')

        response = Onboarding::StatusStepUpdateService
                     .new(current_user, new_users_sign_up_group_path(redirect_params)).execute

        redirect_to response[:step_url]
      else
        flash.now[:alert] = result.errors.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    private

    def permitted_params
      params.permit(
        :company_name,
        :company_size,
        :first_name,
        :last_name,
        :phone_number,
        :country,
        :state,
        :website_url,
        # passed through params
        :role,
        :registration_objective,
        :jobs_to_be_done_other
      ).merge(glm_tracking_params)
    end

    def service_params
      # TODO: As the next step in https://gitlab.com/gitlab-org/gitlab/-/issues/435746, we can remove this
      # passing of trial once we cut over to fully use db solution as this is merely tracking initial
      # trial and so we can merely call that off the user record in the service layer.
      permitted_params.merge(trial_onboarding_flow: true, trial: onboarding_status.trial_from_the_beginning?)
    end

    def redirect_params
      # TODO: As the next step in https://gitlab.com/gitlab-org/gitlab/-/issues/435746, we can remove this
      # passing of trial and trial_onboarding_flow once we cut over to fully use db solution as this is
      # merely tracking initial and current states of trial which we are recording in user.onboarding_status now
      # and so we can merely call that in the places that consume this.
      glm_tracking_params.merge(trial_onboarding_flow: true, trial: params[:trial])
    end

    def track_event(action)
      ::Gitlab::Tracking.event(self.class.name, action, user: current_user, label: onboarding_status.tracking_label)
    end

    def onboarding_status
      ::Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, current_user)
    end
    strong_memoize_attr :onboarding_status
  end
end
