# frozen_string_literal: true

module Types
  module Ci
    class RunnerCloudProvisioningOptionsType < BaseUnion
      graphql_name 'CiRunnerCloudProvisioningOptions'
      description 'Options for runner cloud provisioning.'

      UnexpectedProviderType = Class.new(StandardError)

      possible_types ::Types::Ci::RunnerGoogleCloudProvisioningOptionsType

      def self.resolve_type(object, _context)
        case object[:provider]
        when :google_cloud
          ::Types::Ci::RunnerGoogleCloudProvisioningOptionsType
        else
          raise UnexpectedProviderType, 'Unsupported CI runner cloud provider'
        end
      end
    end
  end
end
