# frozen_string_literal: true

module Ai
  module AiResource
    class Issue < Ai::AiResource::BaseAiResource
      include Ai::AiResource::Concerns::Noteable

      def serialize_for_ai(user:, content_limit:)
        ::IssueSerializer.new(current_user: user, project: resource.project) # rubocop: disable CodeReuse/Serializer
                         .represent(resource, {
                           user: user,
                           notes_limit: content_limit,
                           serializer: 'ai',
                           resource: self
                         })
      end

      def current_page_sentence
        unless Feature.enabled?(:ai_prompt_current_page_skip_reader)
          return <<~SENTENCE
            The user is currently on a page that shows an issue which has a description, comments, etc.  Which the user might reference for example as "current", "this" or "that".
            Here is additional data in <resource></resource> tags about the resource the user is working with:
          SENTENCE
        end

        <<~SENTENCE
          The user is currently on a page that displays an issue with a description, comments, etc., which the user might refer to, for example, as 'current', 'this' or 'that'. The data is provided in <resource></resource> tags, and if it is sufficient in answering the question, utilize it instead of using the 'IssueReader' tool.
        SENTENCE
      end
    end
  end
end
