# frozen_string_literal: true

module Mutations
  module Ci
    module Runners
      class ProvisionGoogleCloudRunner < BaseMutation
        graphql_name 'ProvisionGoogleCloudRunner'
        description 'Provisions a runner in Google Cloud.'

        SINGLE_ELEMENT_QUERY_PARAMS = { max_results: 1 }.freeze

        include FindsProject

        authorize :provision_cloud_runner

        argument :dry_run, ::GraphQL::Types::Boolean,
          required: false,
          default_value: false,
          description: 'If true, returns the Terraform script without executing it. ' \
                       'Defaults to false. True is currently not supported.'
        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project to create the runner in.'
        argument :provisioning_machine_type, ::GraphQL::Types::String,
          required: true,
          description: 'Name of the machine type to use for provisioning the runner.'
        argument :provisioning_project_id, ::GraphQL::Types::String,
          required: true,
          description: 'Identifier of the project where the runner is provisioned.'
        argument :provisioning_region, ::GraphQL::Types::String,
          required: true,
          description: 'Name of the region to provision the runner in.'
        argument :provisioning_zone, ::GraphQL::Types::String,
          required: true,
          description: 'Name of the zone to provision the runner in.'
        argument :runner_token, ::GraphQL::Types::String,
          required: false,
          description: 'Authentication token of the runner.'

        field :provisioning_steps, [Types::Ci::RunnerCloudProvisioningStepType],
          null: true,
          description: 'Steps used to provision the runner.'

        def ready?(dry_run: nil, **_args)
          raise Gitlab::Graphql::Errors::ArgumentError, 'mutation can currently only run in dry-run mode' unless dry_run

          super
        end

        def resolve(
          project_path:, provisioning_project_id:, provisioning_region:, provisioning_zone:,
          provisioning_machine_type:, runner_token: nil, **_args
        )
          project = authorized_find!(project_path)

          errors = []

          if runner_token.present?
            runner = ::Ci::Runner.find_by_token(runner_token)
            errors << 'runnerToken is invalid' unless runner
          else
            raise_resource_not_available_error! unless Ability.allowed?(current_user, :create_runner, project)
          end

          errors.compact!

          response = { errors: errors }
          if errors.empty?
            response[:provisioning_steps] = [
              {
                title: 'Terraform script',
                language_identifier: 'terraform',
                instructions:
                  <<~SCRIPT
                    # TODO: Test provisioning runner #{runner_token} on project '#{provisioning_project_id}'
                    # on a #{provisioning_machine_type} machine in #{provisioning_zone}/#{provisioning_region}
                  SCRIPT
              }
            ]
          end

          response
        end
      end
    end
  end
end
