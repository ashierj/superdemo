# frozen_string_literal: true

module Types
  class FeatureFlagType < ::Types::BaseObject
    graphql_name 'FeatureFlag'

    authorize :read_feature_flag

    field :active, GraphQL::Types::Boolean, null: false, description: 'Whether the feature flag is active.'
    field :id, Types::GlobalIDType[::Operations::FeatureFlag],
      null: false,
      description: 'Global ID of the feature flag.'
    field :name, GraphQL::Types::String, null: false, description: 'Name of the feature flag.'
  end
end
