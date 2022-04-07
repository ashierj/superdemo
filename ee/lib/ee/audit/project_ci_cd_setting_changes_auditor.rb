# frozen_string_literal: true
module EE
  module Audit
    class ProjectCiCdSettingChangesAuditor < BaseChangesAuditor
      def initialize(current_user, ci_cd_settings, project)
        @project = project

        super(current_user, ci_cd_settings)
      end

      def execute
        return if model.blank?

        audit_changes(:merge_pipelines_enabled, as: 'merge_pipelines_enabled', entity: @project, model: model)
        audit_changes(:merge_trains_enabled, as: 'merge_trains_enabled', entity: @project, model: model)
      end

      def attributes_from_auditable_model(column)
        {
          from: model.previous_changes[column].first,
          to: model.previous_changes[column].last,
          target_details: @project.full_path
        }
      end
    end
  end
end
