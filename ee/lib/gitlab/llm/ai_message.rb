# frozen_string_literal: true

module Gitlab
  module Llm
    class AiMessage
      include ActiveModel::AttributeAssignment

      ROLE_USER = 'user'
      ROLE_ASSISTANT = 'assistant'
      ROLE_SYSTEM = 'system'
      ALLOWED_ROLES = [ROLE_USER, ROLE_ASSISTANT, ROLE_SYSTEM].freeze

      attr_accessor :id, :request_id, :content, :role, :timestamp, :errors, :extras, :user

      def self.for(action:)
        if action.to_s == 'chat'
          ChatMessage
        else
          self
        end
      end

      def initialize(attributes = {})
        attributes = attributes.with_indifferent_access

        raise ArgumentError, "Invalid role '#{attributes['role']}'" unless ALLOWED_ROLES.include?(attributes['role'])

        assign_attributes(attributes) if attributes

        @id ||= SecureRandom.uuid
        @timestamp ||= Time.current
        @errors ||= []
      end

      def to_h
        {
          id: id,
          request_id: request_id,
          content: content,
          role: role,
          timestamp: timestamp,
          errors: errors,
          extras: extras,
          user: user
        }.with_indifferent_access
      end

      def save!
        raise NoMethodError, "Can't save regular AiMessage."
      end

      def to_global_id
        ::Gitlab::GlobalId.build(self)
      end

      def size
        content&.size.to_i
      end
    end
  end
end
