# frozen_string_literal: true

module Types
  module GoogleCloud
    module ArtifactRegistry
      # rubocop:disable Graphql/AuthorizeTypes -- authorization happens in the service, called from the resolver
      class DockerImageType < BaseObject
        graphql_name 'GoogleCloudArtifactRegistryDockerImage'
        description 'Represents a docker artifact of Google Cloud Artifact Registry'

        include ::Gitlab::Utils::StrongMemoize

        NAME_REGEX = %r{
          \Aprojects/
          (?<project_id>[^/]+)
          /locations/
          (?<location>[^/]+)
          /repositories/
          (?<repository>[^/]+)
          /dockerImages/
          (?<image>.+)@
          (?<digest>.+)\z (?# end)
        }xi

        alias_method :artifact, :object

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Unique image name.'

        field :uri,
          GraphQL::Types::String,
          null: false,
          description: 'Google Cloud URI to access the image.'

        field :tags,
          [GraphQL::Types::String],
          description: 'Tags attached to the image.'

        field :image_size_bytes,
          GraphQL::Types::String,
          description: 'Calculated size of the image.'

        field :upload_time,
          Types::TimeType,
          description: 'Time when the image was uploaded.'

        field :media_type,
          GraphQL::Types::String,
          description: 'Media type of the image.'

        field :build_time,
          Types::TimeType,
          description: 'Time when the image was built.'

        field :update_time,
          Types::TimeType,
          description: 'Time when the image was last updated.'

        field :project_id,
          GraphQL::Types::String,
          null: false,
          description: 'ID of the Google Cloud project.'

        field :location,
          GraphQL::Types::String,
          null: false,
          description: 'Location of the Artifact Registry repository.'

        field :repository,
          GraphQL::Types::String,
          null: false,
          description: 'Repository on the Google Cloud Artifact Registry.'

        field :image,
          GraphQL::Types::String,
          null: false,
          description: "Image's name."

        field :digest,
          GraphQL::Types::String,
          null: false,
          description: "Image's digest."

        field :artifact_registry_image_url,
          GraphQL::Types::String,
          null: false,
          description: 'Google Cloud URL to access the image.'

        def upload_time
          return unless artifact.upload_time

          Time.at(artifact.upload_time.seconds)
        end

        def build_time
          return unless artifact.build_time

          Time.at(artifact.build_time.seconds)
        end

        def update_time
          return unless artifact.update_time

          Time.at(artifact.update_time.seconds)
        end

        def artifact_registry_image_url
          "https://#{artifact.uri}"
        end

        def image
          image_name_data[:image]
        end

        def digest
          image_name_data[:digest]
        end

        def project_id
          image_name_data[:project_id]
        end

        def location
          image_name_data[:location]
        end

        def repository
          image_name_data[:repository]
        end

        private

        def image_name_data
          artifact.name.match(NAME_REGEX)
        end
        strong_memoize_attr :image_name_data
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
