# frozen_string_literal: true

module Boards
  module Issues
    class ListService < Boards::BaseService
      include Gitlab::Utils::StrongMemoize

      def self.valid_params
        IssuesFinder.valid_params
      end

      def execute
        return fetch_issues.order_closed_date_desc if list&.closed?

        fetch_issues.order_by_position_and_priority(with_cte: params[:search].present?)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def metadata
        issues = Issue.arel_table
        keys = metadata_fields.keys
        # TODO: eliminate need for SQL literal fragment
        columns = Arel.sql(metadata_fields.values_at(*keys).join(', '))
        results = Issue.where(id: fetch_issues.select(issues[:id])).pluck(columns)

        Hash[keys.zip(results.flatten)]
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def metadata_fields
        { size: 'COUNT(*)' }
      end

      # We memoize the query here since the finder methods we use are quite complex. This does not memoize the result of the query.
      # rubocop: disable CodeReuse/ActiveRecord
      def fetch_issues
        strong_memoize(:fetch_issues) do
          issues = IssuesFinder.new(current_user, filter_params).execute

          filter(issues).reorder(nil)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def filter(issues)
        # when grouping board issues by epics (used in board swimlanes)
        # we need to get all issues in the board
        # TODO: ignore hidden columns -
        # https://gitlab.com/gitlab-org/gitlab/-/issues/233870
        return issues if params[:all_lists]

        issues = without_board_labels(issues) unless list&.movable? || list&.closed?
        issues = with_list_label(issues) if list&.label?
        issues
      end

      def board
        @board ||= parent.boards.find(params[:board_id])
      end

      def list
        return unless params.key?(:id)

        strong_memoize(:list) do
          id = params[:id]

          if board.lists.loaded?
            board.lists.find { |l| l.id == id }
          else
            board.lists.find(id)
          end
        end
      end

      def filter_params
        set_parent
        set_state
        set_scope
        set_non_archived
        set_attempt_search_optimizations

        params
      end

      def set_parent
        if parent.is_a?(Group)
          params[:group_id] = parent.id
        else
          params[:project_id] = parent.id
        end
      end

      def set_state
        return if params[:all_lists]

        params[:state] = list && list.closed? ? 'closed' : 'opened'
      end

      def set_scope
        params[:include_subgroups] = board.group_board?
      end

      def set_non_archived
        params[:non_archived] = parent.is_a?(Group)
      end

      def set_attempt_search_optimizations
        return unless params[:search].present?

        if board.group_board?
          params[:attempt_group_search_optimizations] = true
        else
          params[:attempt_project_search_optimizations] = true
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def board_label_ids
        @board_label_ids ||= board.lists.movable.pluck(:label_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def without_board_labels(issues)
        return issues unless board_label_ids.any?

        issues.where.not('EXISTS (?)', issues_label_links.limit(1))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def issues_label_links
        LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id").where(label_id: board_label_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def with_list_label(issues)
        issues.where('EXISTS (?)', LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
                                            .where("label_links.label_id = ?", list.label_id).limit(1))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def board_group
        board.group_board? ? parent : parent.group
      end
    end
  end
end

Boards::Issues::ListService.prepend_if_ee('EE::Boards::Issues::ListService')
