# frozen_string_literal: true

module ComplianceManagement
  class UpdateDefaultFrameworkWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always
    urgency :low
    feature_category :compliance_management

    def perform(_user_id, project_id, compliance_framework_id)
      admin_bot = ::Users::Internal.admin_bot
      project = Project.find(project_id)

      Gitlab::Auth::CurrentUserMode.bypass_session!(admin_bot.id) do
        if Feature.enabled?(:assign_compliance_project_service, project)
          ::ComplianceManagement::Frameworks::AssignProjectService
            .new(project, admin_bot, framework: compliance_framework_id)
            .execute
        else
          ::Projects::UpdateService.new(
            project, admin_bot,
            compliance_framework_setting_attributes: { framework: compliance_framework_id }
          ).execute
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e)
    end
  end
end
