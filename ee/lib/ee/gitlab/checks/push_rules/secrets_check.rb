# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class SecretsCheck < ::Gitlab::Checks::BaseBulkChecker
          def validate!
            # Return early and not perform the check if:
            #   1. unless application setting is enabled (regardless of whether it's a gitlab dedicated instance or not)
            #   2. feature flag is disabled for this project (when instance type is not gitlab dedicated)
            #   3. no push rule exist
            #   4. license is not ultimate
            return unless ::Gitlab::CurrentSettings.pre_receive_secret_detection_enabled

            return if ::Gitlab::CurrentSettings.gitlab_dedicated_instance != true &&
              ::Feature.disabled?(:pre_receive_secret_detection_push_check, push_rule.project)

            return unless push_rule && push_rule.project.licensed_feature_available?(:pre_receive_secret_detection)
          end
        end
      end
    end
  end
end
