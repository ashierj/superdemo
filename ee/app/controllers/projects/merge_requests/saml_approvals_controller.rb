# frozen_string_literal: true

module Projects
  module MergeRequests
    class SamlApprovalsController < Projects::ApplicationController
      feature_category :code_review_workflow

      def create
        return render_404 unless merge_request

        result = ::MergeRequests::ApprovalService
          .new(project: project, current_user: current_user)
          .execute(merge_request)

        if result
          flash[:notice] = _("Approved")
        else
          flash[:alert] = _("Approval rejected.")
        end

        redirect_to(
          namespace_project_merge_request_path(
            id: merge_request_iid,
            project_id: merge_request.project,
            namespace_id: merge_request.project.namespace
          )
        )
      end

      private

      def project_id
        project.id
      end

      def group_id
        project.group.id
      end

      def merge_request_iid
        params.permit(:id).fetch(:id)
      end

      def merge_request
        @merge_request ||= MergeRequestsFinder.new(
          current_user,
          group_id: group_id,
          project_id: project_id,
          iids: [merge_request_iid]
        ).execute&.first
      end
    end
  end
end
