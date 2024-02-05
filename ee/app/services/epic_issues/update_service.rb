# frozen_string_literal: true

module EpicIssues
  class UpdateService < BaseService
    attr_reader :epic_issue, :current_user, :params

    def initialize(epic_issue, user, params)
      @epic_issue = epic_issue
      @current_user = user
      @params = params
    end

    def execute
      return error(s_('Insufficient permissions to update relation'), 403) unless permission_to_update_relation?

      move_issue if params[:move_after_id] || params[:move_before_id]
      epic_issue.save!
      success
    rescue ActiveRecord::RecordNotFound
      error(s_('Epic issue not found for given params'), 404)
    end

    private

    def permission_to_update_relation?
      can?(current_user, :admin_issue_relation, epic_issue.issue) && can?(current_user, :admin_epic_relation, epic)
    end

    def move_issue
      before_epic_issue = epic.epic_issues.find(params[:move_before_id]) if params[:move_before_id]
      after_epic_issue = epic.epic_issues.find(params[:move_after_id]) if params[:move_after_id]

      epic_issue.move_between(before_epic_issue, after_epic_issue)
    end

    def epic
      epic_issue.epic
    end
  end
end
