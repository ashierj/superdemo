# frozen_string_literal: true

module API
  class ProjectGoogleCloudIntegration < ::API::Base
    feature_category :integrations

    before { authorize_admin_project }
    before do
      unless ::Feature.enabled?(:google_cloud_integration_onboarding, user_project.root_namespace, type: :beta)
        not_found!
      end
    end

    desc 'Get shell script to create and configure Workload Identity Federation' do
      detail 'This feature is experimental.'
    end
    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/scripts/google_cloud/' do
        params do
          requires :google_cloud_project_id, types: String
          optional(
            :google_cloud_workload_identity_pool_id,
            { types: String, default: 'gitlab-wlif' })
          optional(
            :google_cloud_workload_identity_pool_display_name,
            { types: String, default: 'WLIF for GitLab integration' })
          optional(
            :google_cloud_workload_identity_pool_provider_id,
            { types: String, default: 'gitlab-wlif-oidc-provider' })
          optional(
            :google_cloud_workload_identity_pool_provider_display_name,
            { types: String, default: 'GitLab OIDC provider' })
        end
        get '/create_wlif' do
          env['api.format'] = :binary
          content_type 'text/plain'

          template_path = File.join(
            'ee', 'lib', 'api', 'templates', 'google_cloud_integration_wlif_create.sh.erb')
          template = ERB.new(File.read(template_path))

          locals = {
            google_cloud_project_id:
              declared_params[:google_cloud_project_id],
            google_cloud_workload_identity_pool_id:
              declared_params[:google_cloud_workload_identity_pool_id],
            google_cloud_workload_identity_pool_display_name:
              declared_params[:google_cloud_workload_identity_pool_display_name],
            google_cloud_workload_identity_pool_provider_id:
              declared_params[:google_cloud_workload_identity_pool_provider_id],
            google_cloud_workload_identity_pool_provider_display_name:
              declared_params[:google_cloud_workload_identity_pool_provider_display_name],
            google_cloud_workload_identity_pool_provider_issuer_uri:
              ::GoogleCloudPlatform::GLGO_BASE_URL
          }

          template.result_with_hash(locals)
        end

        desc 'Get shell script to create IAM policy for the Workload Identity Federation principal' do
          detail 'This feature is experimental.'
        end
        params do
          requires :google_cloud_project_id, types: String
          requires :google_cloud_workload_identity_pool_id, types: String
          requires :oidc_claim_name, types: String
          requires :oidc_claim_value, types: String
          requires :google_cloud_iam_role, types: String
        end
        get '/create_iam_policy' do
          env['api.format'] = :binary
          content_type 'text/plain'

          template_path = File.join(
            'ee', 'lib', 'api', 'templates', 'google_cloud_integration_iam_policy_create.sh.erb')
          template = ERB.new(File.read(template_path))

          locals = {
            google_cloud_project_id:
              declared_params[:google_cloud_project_id],
            google_cloud_workload_identity_pool_id:
              declared_params[:google_cloud_workload_identity_pool_id],
            oidc_claim_name: declared_params[:oidc_claim_name],
            oidc_claim_value: declared_params[:oidc_claim_value],
            google_cloud_iam_role: declared_params[:google_cloud_iam_role]
          }

          template.result_with_hash(locals)
        end
      end
    end
  end
end
