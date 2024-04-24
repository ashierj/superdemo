# frozen_string_literal: true

module Resolvers
  module SecurityOrchestration
    class PipelineExecutionPolicyResolver < BaseResolver
      include ResolvesOrchestrationPolicy

      type Types::SecurityOrchestration::PipelineExecutionPolicyType, null: true

      argument :relationship, ::Types::SecurityOrchestration::SecurityPolicyRelationTypeEnum,
        description: 'Filter policies by the given policy relationship.',
        required: false,
        default_value: :direct

      def resolve(**args)
        policies = Security::PipelineExecutionPoliciesFinder.new(context[:current_user], project, args).execute
        construct_pipeline_execution_policies(policies)
      end
    end
  end
end
