# frozen_string_literal: true

module Gitlab
  class NamespacedSessionStore
    def initialize(key, session = Session.current)
      @namespace_key = key
      @session = session
    end

    def initiated?
      !session.nil?
    end

    def [](key)
      return unless session

      session[@namespace_key]&.fetch(key, nil)
    end

    def []=(key, value)
      return unless session

      session[@namespace_key] ||= {}
      session[@namespace_key][key] = value
    end

    private

    attr_reader :session
  end
end
