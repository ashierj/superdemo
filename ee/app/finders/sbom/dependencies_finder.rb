# frozen_string_literal: true

module Sbom
  class DependenciesFinder
    include Gitlab::Utils::StrongMemoize

    def initialize(project_or_group, params: {})
      @project_or_group = project_or_group
      @params = params
    end

    def execute
      @collection = occurrences

      filter_by_package_managers
      filter_by_component_names
      filter_by_licences
      sort
    end

    private

    attr_reader :project_or_group, :params

    def filter_by_package_managers
      return if params[:package_managers].blank?

      @collection = @collection.filter_by_package_managers(params[:package_managers])
    end

    def filter_by_component_names
      return if params[:component_names].blank?

      @collection = @collection.filter_by_component_names(params[:component_names])
    end

    def filter_by_licences
      return if params[:licenses].blank?

      @collection = @collection.by_licenses(params[:licenses])
    end

    def sort_direction
      params[:sort]&.downcase == 'desc' ? 'desc' : 'asc'
    end

    def sort
      case params[:sort_by]
      when 'name'
        @collection.order_by_component_name(sort_direction)
      when 'packager'
        @collection.order_by_package_name(sort_direction)
      when 'license'
        @collection.order_by_spdx_identifier(sort_direction)
      else
        @collection.order_by_id
      end
    end

    def occurrences
      return project_or_group.sbom_occurrences if params[:project_ids].blank? || project?

      Sbom::Occurrence.by_project_ids(project_ids_in_group_hierarchy)
    end

    def project_ids_in_group_hierarchy
      Project
        .id_in(params[:project_ids])
        .for_group_and_its_subgroups(project_or_group)
        .select(:id)
    end

    def project?
      project_or_group.is_a?(::Project)
    end
  end
end
