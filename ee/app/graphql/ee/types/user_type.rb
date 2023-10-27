# frozen_string_literal: true

# noinspection RubyClassModuleNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
module EE
  module Types
    module UserType
      extend ActiveSupport::Concern

      prepended do
        field :workspaces,
          alpha: { milestone: '16.6' },
          description: 'Workspaces owned by the current user.',
          resolver: ::Resolvers::RemoteDevelopment::WorkspacesForCurrentUserResolver
      end
    end
  end
end
