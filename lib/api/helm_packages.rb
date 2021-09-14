# frozen_string_literal: true

###
# API endpoints for the Helm package registry
module API
  class HelmPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Authentication

    feature_category :package_registry

    PACKAGE_FILENAME = 'package.tgz'
    FILE_NAME_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    content_type :binary, 'application/octet-stream'
    content_type :yaml, 'text/yaml'

    formatter :yaml, -> (object, _) { object.serializable_hash.stringify_keys.to_yaml }

    authenticate_with do |accept|
      accept.token_types(:personal_access_token, :deploy_token, :job_token)
            .sent_through(:http_basic_auth)
    end

    before do
      require_packages_enabled!
    end

    params do
      requires :id, type: String, desc: 'The ID or full path of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/helm' do
        desc 'Download a chart index' do
          detail 'This feature was introduced in GitLab 14.0'
        end
        params do
          requires :channel, type: String, desc: 'Helm channel', regexp: Gitlab::Regex.helm_channel_regex
        end

        get ":channel/index.yaml" do
          authorize_read_package!(authorized_user_project)

          packages = Packages::Helm::PackagesFinder.new(authorized_user_project, params[:channel]).execute

          env['api.format'] = :yaml
          present ::Packages::Helm::IndexPresenter.new(params[:id], params[:channel], packages),
                      with: ::API::Entities::Helm::Index
        end

        desc 'Download a chart' do
          detail 'This feature was introduced in GitLab 14.0'
        end
        params do
          requires :channel, type: String, desc: 'Helm channel', regexp: Gitlab::Regex.helm_channel_regex
          requires :file_name, type: String, desc: 'Helm package file name'
        end
        get ":channel/charts/:file_name.tgz", requirements: FILE_NAME_REQUIREMENTS do
          authorize_read_package!(authorized_user_project)

          package_file = Packages::Helm::PackageFilesFinder.new(authorized_user_project, params[:channel], file_name: "#{params[:file_name]}.tgz").most_recent!

          track_package_event('pull_package', :helm, project: authorized_user_project, namespace: authorized_user_project.namespace)

          present_carrierwave_file!(package_file.file)
        end

        desc 'Authorize a chart upload from workhorse' do
          detail 'This feature was introduced in GitLab 14.0'
        end
        params do
          requires :channel, type: String, desc: 'Helm channel', regexp: Gitlab::Regex.helm_channel_regex
        end
        post "api/:channel/charts/authorize" do
          authorize_workhorse!(
            subject: authorized_user_project,
            has_length: false,
            maximum_size: authorized_user_project.actual_limits.helm_max_file_size
          )
        end

        desc 'Upload a chart' do
          detail 'This feature was introduced in GitLab 14.0'
        end
        params do
          requires :channel, type: String, desc: 'Helm channel', regexp: Gitlab::Regex.helm_channel_regex
          requires :chart, type: ::API::Validations::Types::WorkhorseFile, desc: 'The chart file to be published (generated by Multipart middleware)'
        end
        post "api/:channel/charts" do
          authorize_upload!(authorized_user_project)
          bad_request!('File is too large') if authorized_user_project.actual_limits.exceeded?(:helm_max_file_size, params[:chart].size)

          package = ::Packages::CreateTemporaryPackageService.new(
            authorized_user_project, current_user, declared_params.merge(build: current_authenticated_job)
          ).execute(:helm, name: ::Packages::Helm::TEMPORARY_PACKAGE_NAME)

          chart_params = {
            file:      params[:chart],
            file_name: PACKAGE_FILENAME
          }

          chart_package_file = ::Packages::CreatePackageFileService.new(
            package, chart_params.merge(build: current_authenticated_job)
          ).execute

          track_package_event('push_package', :helm, project: authorized_user_project, namespace: authorized_user_project.namespace)

          ::Packages::Helm::ExtractionWorker.perform_async(params[:channel], chart_package_file.id) # rubocop:disable CodeReuse/Worker

          created!
        rescue ObjectStorage::RemoteStoreError => e
          Gitlab::ErrorTracking.track_exception(e, extra: { channel: params[:channel], project_id: authorized_user_project.id })

          forbidden!
        end
      end
    end
  end
end
