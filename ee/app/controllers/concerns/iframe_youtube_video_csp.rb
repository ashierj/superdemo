# frozen_string_literal: true

module IframeYoutubeVideoCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next if policy.directives.blank?

      # youtube-nocookie.com is needed for embeded video for issues_mrs_empty_state experiment
      # https://gitlab.com/gitlab-org/gitlab/-/issues/436480
      frame_src_values = Array.wrap(policy.directives['frame-src']) | ['https://www.youtube-nocookie.com']
      policy.frame_src(*frame_src_values)
    end
  end
end
