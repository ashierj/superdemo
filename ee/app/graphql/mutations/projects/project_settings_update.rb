# frozen_string_literal: true

module Mutations
  module Projects
    class ProjectSettingsUpdate < BaseMutation
      graphql_name 'ProjectSettingsUpdate'

      include FindsProject
      include Gitlab::Utils::StrongMemoize

      authorize :admin_project

      argument :full_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Full Path of the project the settings belong to.'

      argument :duo_features_enabled,
        GraphQL::Types::Boolean,
        required: true,
        description: 'Indicates whether GitLab Duo features are enabled for the project.'

      field :project_settings,
        Types::Projects::SettingType,
        null: false,
        description: 'Project settings after mutation.'

      def resolve(full_path:, **args)
        raise raise_resource_not_available_error! unless allowed?

        project = authorized_find!(full_path)
        ::Projects::UpdateService.new(project, current_user, { project_setting_attributes: args }).execute

        {
          project_settings: project.project_setting,
          errors: errors_on_object(project.project_setting)
        }
      end

      private

      def allowed?
        # TODO clean up via https://gitlab.com/gitlab-org/gitlab/-/issues/440546
        return true if ::Gitlab::Saas.feature_available?(:duo_chat_on_saas)
        return false unless ::License.feature_available?(:code_suggestions)

        if ::CodeSuggestions::SelfManaged::SERVICE_START_DATE.past?
          ::GitlabSubscriptions::AddOnPurchase
            .for_code_suggestions
            .any?
        else # Before service start date
          # TODO: Remove this else branch after the service start date
          ::Gitlab::CurrentSettings.instance_level_code_suggestions_enabled
        end
      end
    end
  end
end
