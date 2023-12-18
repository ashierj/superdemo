# frozen_string_literal: true

module EE
  module API
    module Helpers
      module UserPreferencesHelpers
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          # Remove this code when we moved to charging users for AI features
          # https://gitlab.com/gitlab-org/gitlab/-/issues/431384
          def update_user_namespace_settings(attrs)
            # code_suggestions is on the user's namespace settings
            if attrs[:code_suggestions].present? && ::Feature.disabled?(:code_suggestions_used_by_default, current_user)
              ::NamespaceSettings::UpdateService.new(
                current_user,
                current_user.namespace,
                { code_suggestions: attrs[:code_suggestions] }
              ).execute

              return false unless current_user.namespace.namespace_settings.save!
            end

            attrs.without(:code_suggestions)
          end
        end
      end
    end
  end
end
