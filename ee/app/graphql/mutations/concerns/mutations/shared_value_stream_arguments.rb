# frozen_string_literal: true

module Mutations
  module SharedValueStreamArguments
    extend ActiveSupport::Concern

    included do
      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Value stream name.'
    end
  end
end
