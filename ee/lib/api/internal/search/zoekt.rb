# frozen_string_literal: true

module API
  module Internal
    module Search
      class Zoekt < ::API::Base
        before { authenticate_by_gitlab_shell_token! }

        feature_category :global_search

        namespace 'internal' do
          namespace 'search' do
            namespace 'zoekt' do
              desc 'Get tasks for a zoekt indexer node' do
                detail 'This feature was introduced in GitLab 16.5.'
              end
              params do
                requires "uuid", type: String, desc: 'Indexer node identifier'
                requires "node.url", type: String, desc: 'Location where indexer can be reached'
                requires "disk.all", type: Integer, desc: 'Total disk space'
                requires "disk.used", type: Integer, desc: 'Total disk space utilized'
                requires "disk.free", type: Integer, desc: 'Total disk space available'
                requires "node.name", type: String, desc: 'Name of indexer node'
              end

              get "/:uuid/tasks", urgency: :medium do
                node = ::Search::Zoekt::Node.find_or_initialize_by_task_request(params)

                if node.save
                  { id: node.id }
                else
                  unprocessable_entity!
                end
              end
            end
          end
        end
      end
    end
  end
end
