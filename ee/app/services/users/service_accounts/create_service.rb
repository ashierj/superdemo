# frozen_string_literal: true

module Users
  module ServiceAccounts
    class CreateService < BaseService
      include Gitlab::Utils::StrongMemoize

      attr_accessor :current_user, :params

      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params.dup
      end

      def execute
        return error(error_message, :forbidden) unless can_create_service_account?

        user = create_user

        return error(user.errors.full_messages.to_sentence, :bad_request) unless user.persisted?

        result = declare_user_external(user)
        return error(result[:message].to_sentence, :bad_request) unless result[:status] == :success

        success(user)
      end

      private

      def username_and_email_generator
        Gitlab::Utils::UsernameAndEmailGenerator.new(
          username_prefix: username_prefix,
          email_domain: "noreply.#{Gitlab.config.gitlab.host}"
        )
      end
      strong_memoize_attr :username_and_email_generator

      def username_prefix
        'service_account'
      end

      def can_create_service_account?
        can?(current_user, :admin_service_accounts)
      end

      def create_user
        ::Users::CreateService.new(current_user, default_user_params).execute
      end

      def default_user_params
        {
          name: 'Service account user',
          email: username_and_email_generator.email,
          username: username_and_email_generator.username,
          user_type: :service_account,
          skip_confirmation: true # Bot users should always have their emails confirmed.
        }
      end

      def declare_user_external(user)
        ::Users::UpdateService.new(current_user, { user: user, external: true }).execute
      end

      def error_message
        _('ServiceAccount|User does not have permission to create a service account.')
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end

      def success(user)
        ServiceResponse.success(payload: user)
      end
    end
  end
end
