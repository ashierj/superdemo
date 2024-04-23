# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include Logging
    include Gitlab::Auth::AuthFinders

    before_subscribe :validate_token_scope

    def validate_token_scope
      validate_access_token!(scopes: [:api, :read_api])
    rescue Gitlab::Auth::InsufficientScopeError
      reject
    end

    private

    def notification_payload(_)
      super.merge!(params: params.except(:channel))
    end

    def request
      connection.request
    end
  end
end
