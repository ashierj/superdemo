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
        argument :ephemeral_machine_type, ::Types::GoogleCloud::MachineTypeType,
          required: true,
          description: 'Name of the machine type to use for running jobs.'
        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project to create the runner in.'
        argument :provisioning_project_id, ::Types::GoogleCloud::ProjectType,
          required: true,
          description: 'Identifier of the project where the runner is provisioned.'
        argument :provisioning_region, ::Types::GoogleCloud::RegionType,
          required: true,
          description: 'Name of the region to provision the runner in.'
        argument :provisioning_zone, ::Types::GoogleCloud::ZoneType,
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

        def resolve(project_path:, runner_token: nil, **args)
          project = authorized_find!(project_path)

          response = ::Ci::Runners::CreateGoogleCloudProvisioningStepsService.new(
            project: project,
            current_user: current_user,
            params:
              args.slice(:provisioning_project_id, :provisioning_region, :provisioning_zone, :ephemeral_machine_type)
                .merge(runner_token: runner_token)
          ).execute

          if response.error?
            case response.reason
            when :insufficient_permissions, :internal_error
              raise_resource_not_available_error!(response.message)
            else
              return { errors: response.errors }
            end
          end

          { errors: [], **response.payload }
        end
      end
    end
  end
end
