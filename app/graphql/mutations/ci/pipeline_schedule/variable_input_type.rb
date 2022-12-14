# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class VariableInputType < Types::BaseInputObject
        graphql_name 'PipelineScheduleVariableInput'

        description 'Attributes for the pipeline schedule variable.'

        argument :key, GraphQL::Types::String, required: true, description: 'Name of the variable.'

        argument :value, GraphQL::Types::String, required: true, description: 'Value of the variable.'

        argument :variable_type, Types::Ci::VariableTypeEnum, required: true, description: 'Type of the variable.'
      end
    end
  end
end
