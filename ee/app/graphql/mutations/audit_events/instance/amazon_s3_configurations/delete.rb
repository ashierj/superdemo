# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Instance
      module AmazonS3Configurations
        class Delete < Base
          graphql_name 'AuditEventsInstanceAmazonS3ConfigurationDelete'

          argument :id, ::Types::GlobalIDType[::AuditEvents::Instance::AmazonS3Configuration],
            required: true,
            description: 'ID of the instance-level Amazon S3 configuration to delete.'

          def resolve(id:)
            config = authorized_find!(id: id)

            audit(config, action: :deleted) if config.destroy
            { errors: Array(config.errors) }
          end
        end
      end
    end
  end
end
