# frozen_string_literal: true

module Projects
  class ComplianceFrameworksController < Projects::ApplicationController
    feature_category :compliance_management

    before_action :authorize_admin_compliance_framework!

    def create
      result = ComplianceManagement::Frameworks::AssignProjectService
        .new(project, current_user, compliance_framework_params)
        .execute

      handle_update_result(result)
    end

    private

    def compliance_framework_params
      params.permit(:framework)
    end
  end
end
