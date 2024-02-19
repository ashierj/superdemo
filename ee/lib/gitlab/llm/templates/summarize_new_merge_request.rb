# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class SummarizeNewMergeRequest
        include Gitlab::Utils::StrongMemoize

        CHARACTER_LIMIT = 2000

        def initialize(user, project, params = {})
          @user = user
          @project = project
          @params = params
        end

        def to_prompt
          return if extracted_diff.blank?

          <<~PROMPT
            You are a code assistant, developed to help summarize code in non-technical terms.

            ```
            #{extracted_diff}
            ```

            The code above, enclosed by three ticks, is the code diff of a merge request.

            Write a summary of the changes in couple sentences, the way an expert engineer would summarize the
            changes using simple - generally non-technical - terms.

            You MUST ensure that it is no longer than 1800 characters. A character is considered anything, not only
            letters.
          PROMPT
        end

        private

        attr_reader :user, :project, :params

        def extracted_diff
          compare = CompareService
            .new(source_project, params[:source_branch])
            .execute(project, params[:target_branch])

          return unless compare

          # Extract only the diff strings and discard everything else
          compare.raw_diffs.to_a.map do |raw_diff|
            # Each diff string starts with information about the lines changed,
            # bracketed by @@. Removing this saves us tokens.
            #
            # Ex: @@ -0,0 +1,58 @@\n+# frozen_string_literal: true\n+\n+module MergeRequests\n+

            next if raw_diff.diff.encoding != Encoding::UTF_8 || raw_diff.has_binary_notice?

            diff_output(raw_diff.old_path, raw_diff.new_path, raw_diff.diff.sub(Gitlab::Regex.git_diff_prefix, ""))
          end.join.truncate_words(CHARACTER_LIMIT)
        end
        strong_memoize_attr :extracted_diff

        def diff_output(old_path, new_path, diff)
          <<~DIFF
            --- #{old_path}
            +++ #{new_path}
            #{diff}
          DIFF
        end

        def source_project
          return project unless params[:source_project_id]

          source_project = Project.find_by_id(params[:source_project_id])

          return source_project if source_project.present? && user.can?(:create_merge_request_from, source_project)

          project
        end
      end
    end
  end
end
