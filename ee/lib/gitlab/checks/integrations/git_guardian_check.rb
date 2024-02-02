# frozen_string_literal: true

module Gitlab
  module Checks
    module Integrations
      class GitGuardianCheck < ::Gitlab::Checks::BaseBulkChecker
        BLOB_BYTES_LIMIT = 1.megabyte

        LOG_MESSAGE = 'Starting GitGuardian scan...'

        def initialize(integration_check)
          @changes_access = integration_check.changes_access
        end

        def validate!
          return unless integration_activated?

          logger.log_timed(LOG_MESSAGE) do
            blobs = changed_blobs(timeout: logger.time_left)
            blobs.reject! { |blob| blob.size > BLOB_BYTES_LIMIT || blob.binary }

            response = project.git_guardian_integration.execute(blobs)

            format_git_guardian_response(response)
          end
        end

        private

        def integration_activated?
          integration = project.git_guardian_integration

          integration.present? && integration.activated?
        end

        def changed_blobs(timeout:)
          ::Gitlab::Checks::ChangedBlobs.new(
            project, revisions, bytes_limit: BLOB_BYTES_LIMIT + 1, with_paths: true
          ).execute(timeout: timeout)
        end

        def revisions
          @revisions ||= changes_access
                           .changes
                           .pluck(:newrev) # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck
                           .reject { |revision| ::Gitlab::Git.blank_ref?(revision) }
                           .compact
        end

        def format_git_guardian_response(response)
          return unless response.present?

          message = response.join(",\n")

          raise ::Gitlab::GitAccess::ForbiddenError, message
        end
      end
    end
  end
end
