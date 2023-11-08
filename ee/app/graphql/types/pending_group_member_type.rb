# frozen_string_literal: true

module Types
  class PendingGroupMemberType < ::Types::GroupMemberType
    graphql_name 'PendingGroupMember'
    description 'Represents a Pending Group Membership'

    authorize :admin_group_member

    field :name,
      type: GraphQL::Types::String,
      null: true,
      description: 'Name of the pending group member.'

    field :username,
      type: GraphQL::Types::String,
      null: true,
      description: 'Username of the pending group member.'

    field :email,
      type: GraphQL::Types::String,
      null: true,
      description: "Public email of the pending group member."

    field :web_url,
      type: GraphQL::Types::String,
      null: true,
      description: 'Web URL of the pending group member.'

    field :avatar_url,
      type: GraphQL::Types::String,
      null: true,
      description: "URL to avatar image file of the pending group member."

    field :approved,
      type: GraphQL::Types::Boolean,
      null: true,
      description: "Whether the pending group member has been approved.",
      method: :active?

    field :invited,
      type: GraphQL::Types::Boolean,
      null: true,
      description: "Whether the pending group member has been invited.",
      method: :invite?

    def name
      object.user&.name
    end

    def username
      object.user&.username
    end

    def email
      object.invite_email || object.user.email
    end

    def web_url
      return unless object.user.present?

      Gitlab::Routing.url_helpers.user_url(object.user)
    end

    def avatar_url
      object.user&.avatar_url || GravatarService.new.execute(email)
    end
  end
end
