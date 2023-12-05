# frozen_string_literal: true

module EE
  module MergeRequests
    module ApprovalService
      extend ::Gitlab::Utils::Override
      # 5 seconds is chosen arbitrarily to ensure the user needs to just have re-authenticated to approve
      # Timeframe gives a short grace period for the callback from the identity provider to have processed.
      SAML_APPROVE_TIMEOUT = 5.seconds

      override :execute
      def execute(merge_request)
        # TODO: rename merge request approval setting to require_reauthentication_to_approve
        # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/431346
        if !feature_flag_for_saml_auth_to_approve_enabled?
          return if incorrect_approval_password?(merge_request)
        else
          return super unless merge_request.require_password_to_approve?

          require_saml_auth = approval_requires_saml_auth?(merge_request)

          return if require_saml_auth && !saml_approval_in_time?
          return if incorrect_approval_password?(merge_request) && !require_saml_auth
        end

        super
      end

      private

      def feature_flag_for_saml_auth_to_approve_enabled?
        root_group && ::Feature.enabled?(:ff_require_saml_auth_to_approve, root_group)
      end

      def incorrect_approval_password?(merge_request)
        merge_request.require_password_to_approve? &&
          !::Gitlab::Auth.find_with_user_password(current_user.username, params[:approval_password])
      end

      def approval_requires_saml_auth?(merge_request)
        ::Gitlab::Auth::GroupSaml::SsoEnforcer.access_restricted?(
          user: current_user,
          resource: merge_request.project,
          session_timeout: 0.seconds
        )
      end

      def group
        project.group
      end

      def saml_provider
        group.root_saml_provider
      end

      def root_group
        group&.root_ancestor
      end

      def saml_approval_in_time?
        return false unless saml_provider

        ::Gitlab::Auth::GroupSaml::SsoState
          .new(saml_provider.id)
          .active_since?(SAML_APPROVE_TIMEOUT.ago)
      end

      override :reset_approvals_cache
      def reset_approvals_cache(merge_request)
        merge_request.reset_approval_cache!
      end
    end
  end
end
