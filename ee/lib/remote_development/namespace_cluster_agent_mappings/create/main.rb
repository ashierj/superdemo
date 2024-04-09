# frozen_string_literal: true

module RemoteDevelopment
  module NamespaceClusterAgentMappings
    module Create
      class Main
        include Messages
        extend MessageSupport

        # @param [Hash] value
        # @return [Hash]
        # @raise [UnmatchedResultError]
        def self.main(value)
          initial_result = Result.ok(value)

          result =
            initial_result
              .and_then(ClusterAgentValidator.method(:validate))
              .and_then(MappingCreator.method(:create))
          case result
          in { err: NamespaceClusterAgentMappingAlreadyExists |
            NamespaceClusterAgentMappingCreateFailed |
            NamespaceClusterAgentMappingCreateValidationFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { ok: NamespaceClusterAgentMappingCreateSuccessful => message }
            { status: :success, payload: message.context }
          else
            raise UnmatchedResultError.new(result: result)
          end
        end
      end
    end
  end
end
