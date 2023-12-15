NOTE: The directory structure of this folder mirrors the structure of the GraphQL API schema
under the root `Query` type.

For example:

- `ee/spec/requests/api/graphql/remote_development/cluster_agent/workspaces`
   contains specs which test the `Query.project.clusterAgent.workspaces` field in the GraphQL API schema,
   as well as any other field which contains a `clusterAgent` field or collection.
- `ee/spec/requests/api/graphql/remote_development/current_user/workspaces`
   contains specs which test the `Query.currentUser.workspaces` field in the GraphQL API schema.
- `ee/spec/requests/api/graphql/remote_development/workspace`
   contains specs which test the `Query.workspace` field in the GraphQL API schema.
- `ee/spec/requests/api/graphql/remote_development/workspaces`
  contains specs which test the `Query.workspaces` field in the GraphQL API schema (note that
  only admins may use this field).

The `shared.rb` file in the root contains RSpec shared contexts and examples used by all
specs in this directory.

The `shared.rb` files in the subdirectories contain shared rspec contexts and examples
specific to the query being tested.

This allows the individual spec files to be very DRY and cohesive, yet provide thorough coverage.
