# frozen_string_literal: true

module Ci
  class ProjectCancellationRestriction
    # Checks if cancellation restrictions are applied for piplines and processables
    # based on the given project
    include Gitlab::Utils::StrongMemoize

    def initialize(project)
      @project = project
      @ci_settings = project.ci_cd_settings
    end

    def maintainers_only_allowed?
      return false unless enabled?

      @ci_settings.restrict_pipeline_cancellation_role_maintainer?
    end

    def no_one_allowed?
      return false unless enabled?

      @ci_settings.restrict_pipeline_cancellation_role_no_one?
    end

    def enabled?
      Feature.enabled?(:restrict_pipeline_cancellation_by_role, @project) &&
        @project.licensed_feature_available?(:ci_pipeline_cancellation_restrictions)
    end
    strong_memoize_attr :enabled?
  end
end
