# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Variables
        module Builder
          extend ::Gitlab::Utils::Override

          override :initialize
          def initialize(pipeline)
            super

            @scan_execution_policies_variables_builder =
              ::Gitlab::Ci::Variables::Builder::ScanExecutionPolicies.new(pipeline)
          end

          override :scoped_variables
          def scoped_variables(job, environment:, dependencies:)
            super.tap do |variables|
              variables.concat(scan_execution_policies_variables_builder.variables(job))
            end
          end

          private

          attr_reader :scan_execution_policies_variables_builder
        end
      end
    end
  end
end
