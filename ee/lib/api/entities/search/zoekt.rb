# frozen_string_literal: true

module API
  module Entities
    module Search
      module Zoekt
        class IndexedNamespace < Grape::Entity
          expose :id, documentation: { type: :int, example: 1234 }
          # TODO: migrate away from using shard_id https://gitlab.com/gitlab-org/gitlab/-/issues/429236
          expose :zoekt_node_id, documentation: { type: :int, example: 1234 }, as: :zoekt_shard_id
          expose :zoekt_node_id, documentation: { type: :int, example: 1234 }
          expose :namespace_id, documentation: { type: :int, example: 1234 }
        end

        class Node < Grape::Entity
          expose :id, documentation: { type: :int, example: 1234 }
          expose :index_base_url, documentation: { type: :string, example: 'http://127.0.0.1:6060/' }
          expose :search_base_url, documentation: { type: :string, example: 'http://127.0.0.1:6070/' }
        end

        class ProjectIndexSuccess < Grape::Entity
          expose :job_id do |item|
            item[:job_id]
          end
        end
      end
    end
  end
end
