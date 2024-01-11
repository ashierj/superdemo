# frozen_string_literal: true

# noinspection RubyClassModuleNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
module EE
  module Types
    module CurrentUserType
      extend ActiveSupport::Concern

      prepended do
        field :workspaces,
          description: 'Workspaces owned by the current user.',
          alpha: { milestone: '16.6' },
          resolver: ::Resolvers::RemoteDevelopment::WorkspacesForCurrentUserResolver

        field :duo_chat_available, ::GraphQL::Types::Boolean,
          resolver: ::Resolvers::Ai::UserChatAccessResolver,
          alpha: { milestone: '16.8' },
          description: 'User access to AI chat feature.'
      end
    end
  end
end
