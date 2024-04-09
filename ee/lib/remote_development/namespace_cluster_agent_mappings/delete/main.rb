# frozen_string_literal: true

module RemoteDevelopment
  module NamespaceClusterAgentMappings
    module Delete
      class Main
        include Messages
        extend MessageSupport

        # @param [Has] value
        # @return [Hash]
        # @raise [UnmatchedResultError]
        def self.main(value)
          initial_result = Result.ok(value)

          result =
            initial_result
              .and_then(MappingDeleter.method(:delete))
          case result
          in { err: NamespaceClusterAgentMappingNotFound => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { ok: NamespaceClusterAgentMappingDeleteSuccessful => message }
            { status: :success, payload: message.context }
          else
            raise UnmatchedResultError.new(result: result)
          end
        end
      end
    end
  end
end
