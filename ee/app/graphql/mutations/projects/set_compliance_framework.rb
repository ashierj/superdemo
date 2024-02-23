# frozen_string_literal: true

module Mutations
  module Projects
    class SetComplianceFramework < BaseMutation
      graphql_name 'ProjectSetComplianceFramework'
      description 'Assign (or unset) a compliance framework to a project.'

      authorize :admin_compliance_framework

      argument :project_id, Types::GlobalIDType[::Project],
               required: true,
               description: 'ID of the project to change the compliance framework of.'

      argument :compliance_framework_id, Types::GlobalIDType[::ComplianceManagement::Framework],
               required: false,
               description: 'ID of the compliance framework to assign to the project. Set to `null` to unset.'

      field :project,
            Types::ProjectType,
            null: true,
            description: "Project after mutation."

      def resolve(project_id:, compliance_framework_id:)
        project = GitlabSchema.find_by_gid(project_id).sync

        authorize!(project)

        if Feature.enabled?(:assign_compliance_project_service, project)
          ::ComplianceManagement::Frameworks::AssignProjectService
            .new(project, current_user, framework: compliance_framework_id&.model_id)
            .execute
        else
          ::Projects::UpdateService.new(project, current_user, compliance_framework_setting_attributes: {
            framework: compliance_framework_id&.model_id
          }).execute
        end

        { project: project, errors: errors_on_object(project) }
      end
    end
  end
end
