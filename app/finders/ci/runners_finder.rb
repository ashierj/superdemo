# frozen_string_literal: true

module Ci
  class RunnersFinder < UnionFinder
    include Gitlab::Allowable

    DEFAULT_SORT = 'created_at_desc'

    def initialize(current_user:, params:)
      @params = params
      @group = params.delete(:group)
      @project = params.delete(:project)
      @current_user = current_user
    end

    def execute
      items = if @project
                project_runners
              elsif @group
                group_runners
              else
                all_runners
              end

      items = search(items)
      items = by_active(items)
      items = by_status(items)
      items = by_upgrade_status(items)
      items = by_runner_type(items)
      items = by_tag_list(items)
      items = by_creator_id(items)
      items = by_version_prefix(items)
      items = request_tag_list(items)

      sort(items)
    end

    def sort_key
      allowed_sorts.include?(@params[:sort]) ? @params[:sort] : DEFAULT_SORT
    end

    private

    attr_reader :group, :project

    def allowed_sorts
      %w[contacted_asc contacted_desc created_at_asc created_at_desc created_date token_expires_at_asc token_expires_at_desc]
    end

    def all_runners
      raise Gitlab::Access::AccessDeniedError unless @current_user&.can_admin_all_resources?

      Ci::Runner.all
    end

    def group_runners
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :read_group_runners, @group)

      case @params[:membership]
      when :direct
        Ci::Runner.belonging_to_group(@group.id)
      when :descendants, nil
        Ci::Runner.belonging_to_group_or_project_descendants(@group.id)
      when :all_available
        unless can?(@current_user, :read_group_all_available_runners, @group)
          raise Gitlab::Access::AccessDeniedError
        end

        Ci::Runner.usable_from_scope(@group)
      else
        raise ArgumentError, 'Invalid membership filter'
      end
    end

    def project_runners
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :read_project_runners, @project)

      ::Ci::Runner.owned_or_instance_wide(@project.id)
    end

    def search(items)
      return items unless @params[:search].present?

      items.search(@params[:search])
    end

    def by_active(items)
      return items if @params.exclude?(:active)

      items.active(@params[:active])
    end

    def by_status(items)
      status = @params[:status_status].presence
      return items unless status

      items.with_status(status)
    end

    def by_upgrade_status(items)
      upgrade_status = @params[:upgrade_status]

      return items unless upgrade_status

      unless Ci::RunnerVersion.statuses.key?(upgrade_status)
        raise ArgumentError, "Invalid upgrade status value '#{upgrade_status}'"
      end

      items.with_upgrade_status(upgrade_status)
    end

    def by_runner_type(items)
      runner_type = @params[:type_type].presence
      return items unless runner_type

      items.with_runner_type(runner_type)
    end

    def by_tag_list(items)
      tag_list = @params[:tag_name].presence
      return items unless tag_list

      items.tagged_with(tag_list)
    end

    def by_creator_id(items)
      creator_id = @params[:creator_id].presence
      return items unless creator_id

      items.with_creator_id(creator_id)
    end

    def by_version_prefix(items)
      sanitized_prefix = @params.fetch(:version_prefix, '')[/^[\d+.]+/]
      return items unless sanitized_prefix

      items.with_version_prefix(sanitized_prefix)
    end

    def sort(items)
      items.order_by(sort_key)
    end

    def request_tag_list(items)
      return items if @params.include?(:preload) && !@params.dig(:preload, :tag_name) # Backward-compatible behavior

      items.with_tags
    end
  end
end

Ci::RunnersFinder.prepend_mod
