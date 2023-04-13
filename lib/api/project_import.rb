# frozen_string_literal: true

module API
  class ProjectImport < ::API::Base
    include PaginationParams

    helpers Helpers::ProjectsHelpers
    helpers Helpers::FileUploadHelpers

    feature_category :importers
    urgency :low

    before { authenticate! unless route.settings[:skip_authentication] }

    helpers do
      def import_params
        declared_params(include_missing: false)
      end

      def namespace_from(params, current_user)
        if params[:namespace]
          find_namespace!(params[:namespace])
        else
          current_user.namespace
        end
      end

      def filtered_override_params(params)
        override_params = params.delete(:override_params)
        filter_attributes_using_license!(override_params) if override_params

        override_params
      end
    end

    before do
      forbidden! unless Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Workhorse authorize the project import upload' do
        detail 'This feature was introduced in GitLab 12.9'
        tags ['project_import']
      end
      post 'import/authorize' do
        require_gitlab_workhorse!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        ImportExportUploader.workhorse_authorize(
          has_length: false,
          maximum_size: Gitlab::CurrentSettings.max_import_size.megabytes
        )
      end

      params do
        requires :path, type: String, desc: 'The new project path and name'
        requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The project export file to be imported', documentation: { type: 'file' }
        optional :name, type: String, desc: 'The name of the project to be imported. Defaults to the path of the project if not provided.'
        optional :namespace, type: String, desc: "The ID or name of the namespace that the project will be imported into. Defaults to the current user's namespace."
        optional :overwrite, type: Boolean, default: false, desc: 'If there is a project in the same namespace and with the same name overwrite it'
        optional :override_params,
                 type: Hash,
                 desc: 'New project params to override values in the export' do
          use :optional_project_params
        end
        optional 'file.path', type: String, desc: 'Path to locally stored body (generated by Workhorse)'
        optional 'file.name', type: String, desc: 'Real filename as send in Content-Disposition (generated by Workhorse)'
        optional 'file.type', type: String, desc: 'Real content type as send in Content-Type (generated by Workhorse)'
        optional 'file.size', type: Integer, desc: 'Real size of file (generated by Workhorse)'
        optional 'file.md5', type: String, desc: 'MD5 checksum of the file (generated by Workhorse)'
        optional 'file.sha1', type: String, desc: 'SHA1 checksum of the file (generated by Workhorse)'
        optional 'file.sha256', type: String, desc: 'SHA256 checksum of the file (generated by Workhorse)'
        optional 'file.etag', type: String, desc: 'Etag of the file (generated by Workhorse)'
        optional 'file.remote_id', type: String, desc: 'Remote_id of the file (generated by Workhorse)'
        optional 'file.remote_url', type: String, desc: 'Remote_url of the file (generated by Workhorse)'
      end
      desc 'Create a new project import' do
        detail 'This feature was introduced in GitLab 10.6.'
        success code: 201, model: Entities::ProjectImportStatus
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
        tags ['project_import']
        consumes ['multipart/form-data']
      end
      post 'import' do
        require_gitlab_workhorse!

        check_rate_limit! :project_import, scope: [current_user, :project_import]

        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/21041')

        validate_file!

        response = ::Import::GitlabProjects::CreateProjectService.new(
          current_user,
          params: {
            path: import_params[:path],
            namespace: namespace_from(import_params, current_user),
            name: import_params[:name],
            file: import_params[:file],
            overwrite: import_params[:overwrite],
            override: filtered_override_params(import_params)
          }
        ).execute

        if response.success?
          present(response.payload, with: Entities::ProjectImportStatus)
        else
          render_api_error!(response.message, response.http_status)
        end
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      desc 'Get a project import status' do
        detail 'This feature was introduced in GitLab 10.6.'
        success code: 200, model: Entities::ProjectImportStatus
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
        tags ['project_import']
      end
      route_setting :skip_authentication, true
      get ':id/import' do
        present user_project, with: Entities::ProjectImportStatus
      end

      params do
        requires :url, type: String, desc: 'The URL for the file.'
        requires :path, type: String, desc: 'The new project path and name'
        optional :name, type: String, desc: 'The name of the project to be imported. Defaults to the path of the project if not provided.'
        optional :namespace, type: String, desc: "The ID or name of the namespace that the project will be imported into. Defaults to the current user's namespace."
        optional :overwrite, type: Boolean, default: false, desc: 'If there is a project in the same namespace and with the same name overwrite it'
        optional :override_params,
          type: Hash,
          desc: 'New project params to override values in the export' do
            use :optional_project_params
          end
      end
      desc 'Create a new project import using a remote object storage path' do
        detail 'This feature was introduced in GitLab 13.2.'
        consumes ['multipart/form-data']
        tags ['project_import']
        success code: 201, model: Entities::ProjectImportStatus
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 429, message: 'Too many requests' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      post 'remote-import' do
        check_rate_limit! :project_import, scope: [current_user, :project_import]

        response = ::Import::GitlabProjects::CreateProjectService.new(
          current_user,
          params: {
            path: import_params[:path],
            namespace: namespace_from(import_params, current_user),
            name: import_params[:name],
            remote_import_url: import_params[:url],
            overwrite: import_params[:overwrite],
            override: filtered_override_params(import_params)
          },
          file_acquisition_strategy: ::Import::GitlabProjects::FileAcquisitionStrategies::RemoteFile
        ).execute

        if response.success?
          present(response.payload, with: Entities::ProjectImportStatus)
        else
          render_api_error!(response.message, response.http_status)
        end
      end

      params do
        requires :region, type: String, desc: 'AWS region'
        requires :bucket_name, type: String, desc: 'Bucket name'
        requires :file_key, type: String, desc: 'File key'
        requires :access_key_id, type: String, desc: 'Access key id'
        requires :secret_access_key, type: String, desc: 'Secret access key'
        requires :path, type: String, desc: 'The new project path and name'
        optional :name, type: String, desc: 'The name of the project to be imported. Defaults to the path of the project if not provided.'
        optional :namespace, type: String, desc: "The ID or name of the namespace that the project will be imported into. Defaults to the current user's namespace."
        optional :overwrite, type: Boolean, default: false, desc: 'If there is a project in the same namespace and with the same name overwrite it'
        optional :override_params,
          type: Hash,
          desc: 'New project params to override values in the export' do
            use :optional_project_params
          end
      end
      desc 'Create a new project import using a file from AWS S3' do
        detail 'This feature was introduced in GitLab 14.9.'
        consumes ['multipart/form-data']
        tags ['project_import']
        success code: 201, model: Entities::ProjectImportStatus
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 429, message: 'Too many requests' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      post 'remote-import-s3' do
        check_rate_limit! :project_import, scope: [current_user, :project_import]

        response = ::Import::GitlabProjects::CreateProjectService.new(
          current_user,
          params: {
            path: import_params[:path],
            namespace: namespace_from(import_params, current_user),
            name: import_params[:name],
            overwrite: import_params[:overwrite],
            override: filtered_override_params(import_params),
            region: import_params[:region],
            bucket_name: import_params[:bucket_name],
            file_key: import_params[:file_key],
            access_key_id: import_params[:access_key_id],
            secret_access_key: import_params[:secret_access_key]
          },
          file_acquisition_strategy: ::Import::GitlabProjects::FileAcquisitionStrategies::RemoteFileS3
        ).execute

        if response.success?
          present(response.payload, with: Entities::ProjectImportStatus)
        else
          render_api_error!(response.message, response.http_status)
        end
      end
    end
  end
end
