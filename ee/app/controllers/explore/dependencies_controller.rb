# frozen_string_literal: true

# Warning: The group level Dependency list has experienced quite a few
# performance problems when adding features like filtering,
# grouping, sorting, and advanced pagination. Because of this
# the group level Dependency list is limited to groups that are
# below a specific threshold. Those same limits have not been
# considered or added here yet.
#
# See https://gitlab.com/gitlab-org/gitlab/-/blob/b3d0d3b3633e04cabe5de1359fa1d93ba824d142/ee/app/controllers/groups/dependencies_controller.rb#L18-19
# for additional context.

module Explore
  class DependenciesController < ::Explore::ApplicationController
    DEFAULT_PAGE_SIZE = 20
    feature_category :dependency_management
    urgency :low

    before_action :authorize_explore_dependencies!

    before_action do
      push_frontend_feature_flag(:explore_dependencies, current_user)
    end

    def index
      respond_to do |format|
        format.html do
          render status: :ok
        end
        format.json do
          render json: serializer.represent(dependencies)
        end
      end
    end

    private

    def finder
      ::Sbom::DependenciesFinder.new(
        organization,
        params: finder_params
      )
    end

    def finder_params
      params.permit(:page, :per_page)
    end

    def serializer
      DependencyListSerializer
        .new(organization: organization, user: current_user)
        .with_pagination(request, response)
    end

    def organization
      @organization ||= current_user.organizations.default_organization
    end

    def dependencies
      finder
        .execute
        .page(finder_params[:page])
        .per(DEFAULT_PAGE_SIZE)
        .with_component
        .with_project_namespace
        .with_project_route
        .with_source
        .with_version
        .without_count
    end

    def authorize_explore_dependencies!
      return render_404 unless current_user.present?
      return render_404 unless Feature.enabled?(:explore_dependencies, current_user)

      render_403 unless can?(current_user, :read_dependency, organization)
    end
  end
end
