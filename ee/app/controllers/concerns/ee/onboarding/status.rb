# frozen_string_literal: true

module EE
  module Onboarding
    module Status
      PRODUCT_INTERACTION = {
        free: 'Personal SaaS Registration',
        trial: 'SaaS Trial',
        automatic_trial: 'SaaS Trial - defaulted',
        invite: 'Invited User',
        lead: 'SaaS Registration'
      }.freeze

      TRACKING_LABEL = {
        free: 'free_registration',
        trial: 'trial_registration',
        invite: 'invite_registration',
        subscription: 'subscription_registration'
      }.freeze

      REGISTRATION_TYPE = {
        free: 'free',
        trial: 'trial',
        invite: 'invite',
        subscription: 'subscription'
      }.freeze

      module ClassMethods
        def enabled?
          ::Gitlab::Saas.feature_available?(:onboarding)
        end
      end

      def self.prepended(base)
        base.singleton_class.prepend ClassMethods
      end

      def continue_full_onboarding?
        !subscription? &&
          !invite? &&
          !oauth? &&
          enabled?
      end

      def joining_a_project?
        ::Gitlab::Utils.to_boolean(params[:joining_project], default: false)
      end

      def redirect_to_company_form?
        trial? || converted_to_automatic_trial?
      end

      def convert_to_automatic_trial?
        # TODO: Basically only free, but this logic may go away soon as we start the next step in
        # https://gitlab.com/gitlab-org/gitlab/-/issues/453979
        return false if invite? || subscription? || trial?

        setup_for_company?
      end

      def invite?
        # TODO: As the next step in https://gitlab.com/gitlab-org/gitlab/-/issues/435746, we can remove the
        # invited_registration_type? from this logic as we will be fully driving off the db value.

        if ::Feature.disabled?(:use_only_onboarding_status_db_value, user)
          return user.onboarding_status_registration_type == REGISTRATION_TYPE[:invite] || invited_registration_type?
        end

        user.onboarding_status_registration_type == REGISTRATION_TYPE[:invite]
      end

      def trial?
        # TODO: As the next step in https://gitlab.com/gitlab-org/gitlab/-/issues/435746, we can remove the
        # the params and stored location considerations as we will be fully driving off the db registration_type.
        return false unless enabled?

        if ::Feature.disabled?(:use_only_onboarding_status_db_value, user)
          return user.onboarding_status_registration_type == REGISTRATION_TYPE[:trial] ||
              trial_from_params? || trial_from_stored_location?
        end

        user.onboarding_status_registration_type == REGISTRATION_TYPE[:trial]
      end

      def oauth?
        # During authorization for oauth, we want to allow it to finish.
        return false unless base_stored_user_location_path.present?

        base_stored_user_location_path == ::Gitlab::Routing.url_helpers.oauth_authorization_path
      end

      def tracking_label
        return TRACKING_LABEL[:trial] if trial?
        return TRACKING_LABEL[:invite] if invite?
        return TRACKING_LABEL[:subscription] if subscription?

        TRACKING_LABEL[:free]
      end

      def preregistration_tracking_label
        # Trial registrations do not call this right now, so we'll omit it here from consideration.
        return TRACKING_LABEL[:invite] if params[:invite_email]
        return TRACKING_LABEL[:subscription] if subscription_from_stored_location?

        TRACKING_LABEL[:free]
      end

      def group_creation_tracking_label
        return TRACKING_LABEL[:trial] if trial_onboarding_flow? || trial?

        TRACKING_LABEL[:free]
      end

      def onboarding_tracking_label
        return TRACKING_LABEL[:trial] if trial_onboarding_flow?

        TRACKING_LABEL[:free]
      end

      def trial_onboarding_flow?
        # This only comes from the submission of the company form.
        # It is then passed around to creating group/project
        # and then back to welcome controller for the
        # continuous getting started action.
        ::Gitlab::Utils.to_boolean(params[:trial_onboarding_flow], default: false)
      end

      def setup_for_company?
        ::Gitlab::Utils.to_boolean(params.dig(:user, :setup_for_company), default: false)
      end
      alias_method :converted_to_automatic_trial?, :setup_for_company?

      def enabled?
        self.class.enabled?
      end

      def subscription?
        return false unless enabled?

        if ::Feature.disabled?(:use_only_onboarding_status_db_value, user)
          return user.onboarding_status_registration_type == REGISTRATION_TYPE[:subscription] ||
              subscription_from_stored_location?
        end

        user.onboarding_status_registration_type == REGISTRATION_TYPE[:subscription]
      end

      def iterable_product_interaction
        if invite?
          PRODUCT_INTERACTION[:invite]
        else
          PRODUCT_INTERACTION[:free]
        end
      end

      def company_lead_product_interaction
        if trial? && initial_trial?
          PRODUCT_INTERACTION[:trial]
        else
          # Due to this only being called in an area where only trials reach,
          # we can assume and not check for free/invite/subscription/etc here.
          PRODUCT_INTERACTION[:automatic_trial]
        end
      end

      def trial_from_the_beginning?
        # We do not need to consider trial_from_stored_location? here as this is only used in the
        # identity_verification area and this method is not called there.
        # TODO: We can simplify/remove this method once we cutover to DB only solution as the next step in
        # https://gitlab.com/gitlab-org/gitlab/-/issues/435746.

        if ::Feature.disabled?(:use_only_onboarding_status_db_value, user)
          return trial_from_params? || (user.onboarding_status_initial_registration_type.present? && initial_trial?)
        end

        initial_trial?
      end

      def eligible_for_iterable_trigger?
        return false if trial?
        # The invite check coming first matters now in the case of a welcome form with company params
        # being received when the user is really an invite.
        # This covers the case for user being added to a group after they register, but
        # before they finish the welcome step.
        return true if invite?
        # skip company page because it already sends request to CustomersDot
        return false if redirect_to_company_form?

        # regular registration
        continue_full_onboarding?
      end

      def stored_user_location
        # side effect free look at devise store_location_for(:user)
        session['user_return_to']
      end

      private

      attr_reader :params, :session

      def trial_from_params?
        ::Gitlab::Utils.to_boolean(params[:trial], default: false)
      end

      def subscription_from_stored_location?
        # TODO: As the next step in https://gitlab.com/gitlab-org/gitlab/-/issues/435746, we can remove the
        # subscription_from_stored_location? alias and use as we will drive off the DB.
        # This method will need to remain though long term.
        base_stored_user_location_path == ::Gitlab::Routing.url_helpers.new_subscriptions_path
      end

      def invited_registration_type?
        members.any?
      end

      def initial_trial?
        # TODO: As the next step in https://gitlab.com/gitlab-org/gitlab/-/issues/435746, we can remove the
        # return true condition here and simplify this area as we drive off the db values.
        return true unless user.onboarding_status_initial_registration_type

        user.onboarding_status_initial_registration_type == REGISTRATION_TYPE[:trial]
      end

      def base_stored_user_location_path
        return unless stored_user_location

        URI.parse(stored_user_location).path
      end

      def stored_redirect_location
        # side effect free look at devise stored_location_for(:redirect)
        session['redirect_return_to']
      end

      def trial_from_stored_location?
        # TODO: See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143148
        # This is used for detection of proper tracking in the identity_verification
        # area. We can also look to remove this in the next step where we rely
        # on the database in https://gitlab.com/gitlab-org/gitlab/-/issues/435746.
        return false unless session

        # for regular signup it will be in `redirect`, but for SSO it will be in `user`
        redirect_to_location = stored_redirect_location || stored_user_location
        return false unless redirect_to_location

        uri = URI.parse(redirect_to_location)

        return false unless uri.query

        URI.decode_www_form(uri.query).to_h['trial'] == 'true'
      end
    end
  end
end
