# frozen_string_literal: true

module Types
  module Ci
    class RunnerGoogleCloudProvisioningOptionsType < BaseObject
      graphql_name 'CiRunnerGoogleCloudProvisioningOptions'
      description 'Options for runner Google Cloud provisioning.'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_runner_cloud_provisioning_options

      field :regions, Types::Ci::RunnerCloudProvisioningRegionType.connection_type,
        description: 'Regions available for provisioning a runner.',
        null: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        max_page_size: GoogleCloudPlatform::Compute::ListRegionsService::MAX_RESULTS_LIMIT,
        default_page_size: GoogleCloudPlatform::Compute::ListRegionsService::MAX_RESULTS_LIMIT

      field :zones, Types::Ci::RunnerCloudProvisioningZoneType.connection_type,
        description: 'Zones available for provisioning a runner.',
        null: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        max_page_size: GoogleCloudPlatform::Compute::ListZonesService::MAX_RESULTS_LIMIT,
        default_page_size: GoogleCloudPlatform::Compute::ListZonesService::MAX_RESULTS_LIMIT do
          argument :region, GraphQL::Types::String, required: false,
            description: 'Region to retrieve zones for. Returns all zones if not specified.'
        end

      field :machine_types,
        Types::Ci::RunnerCloudProvisioningMachineTypeType.connection_type,
        description: 'Machine types available for provisioning a runner.',
        null: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        max_page_size: GoogleCloudPlatform::Compute::ListMachineTypesService::MAX_RESULTS_LIMIT,
        default_page_size: GoogleCloudPlatform::Compute::ListMachineTypesService::MAX_RESULTS_LIMIT do
          argument :zone, GraphQL::Types::String, required: true, description: 'Zone to retrieve machine types for.'
        end

      field :project_setup_shell_script, GraphQL::Types::String, null: true,
        description: 'Instructions for setting up a Google Cloud project.'

      def self.authorized?(object, context)
        super(object[:project], context)
      end

      def regions(after: nil, first: nil)
        response = GoogleCloudPlatform::Compute::ListRegionsService
          .new(project: project, current_user: current_user,
            params: default_params(after, first).merge(google_cloud_project_id: google_cloud_project_id))
          .execute

        externally_paginated_array(response, after)
      end

      def zones(region: nil, after: nil, first: nil)
        params = default_params(after, first)
        params[:filter] = "name=#{region}-*" if region
        params[:google_cloud_project_id] = google_cloud_project_id if google_cloud_project_id

        response = GoogleCloudPlatform::Compute::ListZonesService
          .new(project: project, current_user: current_user, params: params)
          .execute

        externally_paginated_array(response, after)
      end

      def machine_types(zone:, after: nil, first: nil)
        response = GoogleCloudPlatform::Compute::ListMachineTypesService
          .new(
            project: project, current_user: current_user, zone: zone,
            params: default_params(after, first).merge(google_cloud_project_id: google_cloud_project_id)
          )
          .execute

        externally_paginated_array(response, after)
      end

      def project_setup_shell_script # rubocop:disable GraphQL/ResolverMethodLength -- this method's purpose is to return a full script, so it's bound to be long
        <<~SHELL
          #!/bin/bash

          set -exo pipefail

          # Set up variables
          PROJECT_ID="#{object[:cloud_project_id]}"
          SERVICE_ACCOUNT_NAME="grit-provisioner"
          ROLE_NAME="GRITProvisioner"
          IAM_ROLE="projects/$PROJECT_ID/roles/GRITProvisioner"

          # Create a new project and set it as default
          gcloud config set project $PROJECT_ID || gcloud projects create $PROJECT_ID --name=$PROJECT_ID --set-as-default

          # Set up services required for runner provisioning
          gcloud services enable cloudkms.googleapis.com compute.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com

          # Set up services required for runner execution
          gcloud services enable iamcredentials.googleapis.com oslogin.googleapis.com

          # Prepare roles permissions definition file
          temp_dir="$(mktemp --directory)"
          provisioner_role_json_path="$(mktemp $temp_dir/grit-provisioner-role.XXXX.json)"
          cat <<EOF > $provisioner_role_json_path
          {
            "title": "GRITProvisioner",
            "description": "A role with minimum list of permissions required for GRIT provisioning",
            "includedPermissions": [
              "cloudkms.cryptoKeyVersions.destroy",
              "cloudkms.cryptoKeyVersions.list",
              "cloudkms.cryptoKeyVersions.useToEncrypt",
              "cloudkms.cryptoKeys.create",
              "cloudkms.cryptoKeys.get",
              "cloudkms.cryptoKeys.update",
              "cloudkms.keyRings.create",
              "cloudkms.keyRings.get",
              "compute.disks.create",
              "compute.firewalls.create",
              "compute.firewalls.delete",
              "compute.firewalls.get",
              "compute.instanceGroupManagers.create",
              "compute.instanceGroupManagers.delete",
              "compute.instanceGroupManagers.get",
              "compute.instanceGroups.create",
              "compute.instanceGroups.delete",
              "compute.instanceTemplates.create",
              "compute.instanceTemplates.delete",
              "compute.instanceTemplates.get",
              "compute.instanceTemplates.useReadOnly",
              "compute.instances.create",
              "compute.instances.delete",
              "compute.instances.get",
              "compute.instances.setLabels",
              "compute.instances.setMetadata",
              "compute.instances.setServiceAccount",
              "compute.instances.setTags",
              "compute.networks.create",
              "compute.networks.delete",
              "compute.networks.get",
              "compute.networks.updatePolicy",
              "compute.subnetworks.create",
              "compute.subnetworks.delete",
              "compute.subnetworks.get",
              "compute.subnetworks.use",
              "compute.subnetworks.useExternalIp",
              "compute.zones.get",
              "iam.roles.create",
              "iam.roles.delete",
              "iam.roles.get",
              "iam.roles.list",
              "iam.roles.update",
              "iam.serviceAccounts.actAs",
              "iam.serviceAccounts.create",
              "iam.serviceAccounts.delete",
              "iam.serviceAccounts.get",
              "iam.serviceAccounts.list",
              "resourcemanager.projects.get",
              "resourcemanager.projects.getIamPolicy",
              "resourcemanager.projects.setIamPolicy",
              "storage.buckets.create",
              "storage.buckets.delete",
              "storage.buckets.get",
              "storage.buckets.getIamPolicy",
              "storage.buckets.setIamPolicy"
            ],
            "stage": "BETA"
          }
          EOF

          # Setup of provisioning permissions
          gcloud iam roles create $ROLE_NAME --project=$PROJECT_ID --file="$provisioner_role_json_path" || echo "$ROLE_NAME role already created"
          gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name='GRIT provisioner' --description='Service account for GRIT provisioning' || echo "Service account $SERVICE_ACCOUNT_NAME already created"

          rm -rf "$temp_dir"
        SHELL
      end

      private

      def project
        object[:project]
      end

      def google_cloud_project_id
        object[:cloud_project_id]
      end

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
  end
end
