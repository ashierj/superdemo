# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class CiConfigurationService
      ACTION_CLASSES = {
        'secret_detection' => CiAction::Template,
        'container_scanning' => CiAction::Template,
        'sast' => CiAction::Template,
        'sast_iac' => CiAction::Template,
        'dependency_scanning' => CiAction::Template,
        'custom' => CiAction::Custom
      }.freeze

      def execute(action, ci_variables, context, index = 0)
        action_class = ACTION_CLASSES[action[:scan]] || CiAction::Unknown

        action_class.new(action, ci_variables, context, index).config
      end
    end
  end
end
