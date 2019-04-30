# frozen_string_literal: true

class Vulnerabilities::FeedbackEntity < Grape::Entity
  include Gitlab::Routing
  include GitlabRoutingHelper

  expose :id
  expose :created_at
  expose :project_id
  expose :author, using: UserEntity
  expose :comment_details, if: -> (feedback, _) { feedback.comment.present? } do
    expose :comment
    expose :comment_timestamp
    expose :comment_author, using: UserEntity
  end

  expose :pipeline, if: -> (feedback, _) { feedback.pipeline.present? } do
    expose :id do |feedback|
      feedback.pipeline.id
    end

    expose :path do |feedback|
      project_pipeline_path(feedback.pipeline.project, feedback.pipeline)
    end
  end

  expose :issue_iid, if: -> (feedback, _) { feedback.issue.present? } do |feedback|
    feedback.issue.iid
  end

  expose :issue_url, if: -> (feedback, _) { feedback.issue.present? } do |feedback|
    project_issue_url(feedback.project, feedback.issue)
  end

  expose :merge_request_iid, if: -> (feedback, _) { feedback.merge_request.present? } do |feedback|
    feedback.merge_request.iid
  end

  expose :merge_request_path, if: -> (feedback, _) { feedback.merge_request.present? } do |feedback|
    project_merge_request_path(feedback.project, feedback.merge_request)
  end

  expose :category
  expose :feedback_type
  expose :branch do |feedback|
    feedback&.pipeline&.ref
  end
  expose :project_fingerprint
end
