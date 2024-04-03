# frozen_string_literal: true

module EE
  module MergeRequestsHelper
    extend ::Gitlab::Utils::Override

    def render_items_list(items, separator = "and")
      items_cnt = items.size

      case items_cnt
      when 1
        items.first
      when 2
        "#{items.first} #{separator} #{items.last}"
      else
        last_item = items.pop
        "#{items.join(", ")} #{separator} #{last_item}"
      end
    end

    override :diffs_tab_pane_data
    def diffs_tab_pane_data(project, merge_request, params)
      data = {
        endpoint_codequality: (codequality_mr_diff_reports_project_merge_request_path(project, merge_request, 'json') if project.licensed_feature_available?(:inline_codequality) && merge_request.has_codequality_mr_diff_report?),
        sast_report_available: merge_request.has_sast_reports?.to_s
      }

      data[:codequality_report_available] = merge_request.has_codequality_reports?.to_s if project.licensed_feature_available?(:inline_codequality)

      super.merge(data)
    end

    override :mr_compare_form_data
    def mr_compare_form_data(user, merge_request)
      target_branch_finder_path = if can?(user, :read_target_branch_rule, merge_request.project)
                                    project_target_branch_rules_path(merge_request.project)
                                  end

      super.merge({ target_branch_finder_path: target_branch_finder_path })
    end

    def summarize_llm_enabled?(project)
      ::Llm::MergeRequests::SummarizeDiffService.enabled?(group: project.root_ancestor)
    end

    override :review_bar_data
    def review_bar_data(merge_request, user)
      super.merge({ can_summarize: Ability.allowed?(user, :summarize_draft_code_review, merge_request).to_s })
    end

    def diff_llm_summary(merge_request)
      merge_request.latest_merge_request_diff&.merge_request_diff_llm_summary
    end

    def truncated_diff_llm_summary(merge_request)
      diff_llm_summary(merge_request).content.truncate(250)
    end

    def review_llm_summary_allowed?(merge_request, user)
      Ability.allowed?(user, :summarize_submitted_review, merge_request)
    end

    def review_llm_summary(merge_request, reviewer)
      merge_request.latest_merge_request_diff&.latest_review_summary_from_reviewer(reviewer)
    end

    def show_video_component?(project)
      experiment(:issues_mrs_empty_state, type: :experiment, user: current_user, project: project) do |e|
        e.control { false }
        e.candidate { true }
      end.run
    end
  end
end
