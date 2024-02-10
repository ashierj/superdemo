# frozen_string_literal: true

module Resolvers
  module Ci
    # rubocop: disable Graphql/ResolverType -- the type is decided on the derived resolver class
    class RunnerCloudProvisioningBaseResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_runner_cloud_provisioning_options

      private

      alias_method :project, :object

      def default_params(after, first)
        { max_results: first, page_token: after }.compact
      end

      def externally_paginated_array(response, after)
        raise_resource_not_available_error!(response.message) if response.error?

        Gitlab::Graphql::ExternallyPaginatedArray.new(
          after,
          response.payload[:next_page_token],
          *response.payload[:items]
        )
      end
    end
    # rubocop: enable Graphql/ResolverType
  end
end
