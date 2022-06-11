# frozen_string_literal: true

module Resolvers
  module Crm
    class ContactsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_crm_contact

      type Types::CustomerRelations::ContactType, null: true

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search term to find contacts with.'

      argument :state, Types::CustomerRelations::ContactStateEnum,
               required: false,
               description: 'State of the contacts to search for.'

      argument :ids, [GraphQL::Types::ID],
               required: false,
               description: 'Filter contacts by IDs.'

      def resolve(**args)
        args[:ids] = parse_gids(args.delete(:ids))

        ::Crm::ContactsFinder.new(current_user, { group: group }.merge(args)).execute
      end

      def group
        object.respond_to?(:sync) ? object.sync : object
      end

      private

      def parse_gids(gids)
        gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: CustomerRelations::Contact).model_id }
      end
    end
  end
end
