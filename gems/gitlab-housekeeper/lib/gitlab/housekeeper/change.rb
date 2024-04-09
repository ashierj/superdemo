# frozen_string_literal: true

require 'gitlab/housekeeper/push_options'

module Gitlab
  module Housekeeper
    class Change
      attr_accessor :identifiers,
        :title,
        :description,
        :changed_files,
        :labels,
        :keep_class,
        :changelog_type,
        :mr_web_url,
        :push_options
      attr_reader :reviewers

      def initialize
        @labels = []
        @reviewers = []
        @push_options = PushOptions.new
      end

      def reviewers=(reviewers)
        @reviewers = Array(reviewers)
      end

      def mr_description
        <<~MARKDOWN
        #{description}

        This change was generated by
        [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
        using the #{keep_class} keep.

        To provide feedback on your experience with `gitlab-housekeeper` please comment in
        <https://gitlab.com/gitlab-org/gitlab/-/issues/442003>.
        MARKDOWN
      end

      def commit_message
        <<~MARKDOWN
        #{title}

        #{mr_description}

        Changelog: #{changelog_type || 'other'}
        MARKDOWN
      end

      def matches_filters?(filters)
        filters.all? do |filter|
          identifiers.any? do |identifier|
            identifier.match?(filter)
          end
        end
      end

      def valid?
        @identifiers && @title && @description && @changed_files
      end
    end
  end
end
