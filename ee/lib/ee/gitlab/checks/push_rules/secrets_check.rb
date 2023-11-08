# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class SecretsCheck < ::Gitlab::Checks::BaseBulkChecker
          def validate!
            # Return early and not perform the check if:
            #   1. no push rule exist
            #   2. and license is not ultimate
            #   3. and feature flag is disabled
            return unless push_rule &&
              push_rule.project.licensed_feature_available?(:pre_receive_secret_detection) &&
              ::Feature.enabled?(:pre_receive_secret_detection_push_check, push_rule.project)
          end
        end
      end
    end
  end
end
