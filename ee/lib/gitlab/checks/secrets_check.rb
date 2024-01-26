# frozen_string_literal: true

module Gitlab
  module Checks
    class SecretsCheck < ::Gitlab::Checks::BaseBulkChecker
      ERROR_MESSAGES = {
        failed_to_scan_regex_error: "\n    - Failed to scan blob(id: %{blob_id}) due to regex error.",
        blob_timed_out_error: "\n    - Scanning blob(id: %{blob_id}) timed out.",
        scan_timeout_error: 'Secret detection scan timed out.',
        scan_initialization_error: 'Secret detection scan failed to initialize.',
        invalid_input_error: 'Secret detection scan failed due to invalid input.',
        invalid_scan_status_code_error: 'Invalid secret detection scan status, check passed.',
        too_many_tree_entries_error: 'Too many tree entries exist for commit(sha: %{sha}).'
      }.freeze

      LOG_MESSAGES = {
        secrets_check: 'Detecting secrets...',
        secrets_not_found: 'Secret detection scan completed with no findings.',
        skip_secret_detection: "\n\nIf you wish to skip secret detection, please include [skip secret detection] " \
                               "in one of the commit messages for your changes.",
        found_secrets: 'Secret detection scan completed with one or more findings.',
        found_secrets_post_message: "\n\nPlease remove the identified secrets in your commits and try again.",
        found_secrets_docs_link: "\nFor help with this, please refer to our documentation: %{path}",
        found_secrets_with_errors: 'Secret detection scan completed with one or more findings ' \
                                   'but some errors occured during the scan.',
        finding_message_occurrence_header: "\n\nSecrets leaked in commit: %{sha}",
        finding_message_occurrence_path: "\n  - path: %{path}",
        finding_message_occurrence_line: "\n    - line:%{line_number} | %{description}",
        finding_message: "\n\nSecret leaked in blob: %{blob_id}" \
                         "\n  -- line:%{line_number} | %{description}"
      }.freeze

      BLOB_BYTES_LIMIT = 1.megabyte # Limit is 1MiB to start with.
      SPECIAL_COMMIT_FLAG = /\[skip secret detection\]/i
      DOCUMENTATION_PATH = 'user/application_security/secret_detection/pre_receive.html'
      DOCUMENTATION_PATH_ANCHOR = 'resolve-a-blocked-push'

      def validate!
        # Return early and not perform the check if:
        #   1. unless application setting is enabled (regardless of whether it's a gitlab dedicated instance or not)
        #   2. feature flag is disabled for this project (when instance type is not gitlab dedicated)
        #   3. license is not ultimate
        return unless ::Gitlab::CurrentSettings.pre_receive_secret_detection_enabled

        return unless ::Gitlab::CurrentSettings.gitlab_dedicated_instance ||
          ::Feature.enabled?(:pre_receive_secret_detection_push_check, project)

        return unless project.licensed_feature_available?(:pre_receive_secret_detection)

        # Skip if any commit has the special bypass flag `[skip secret detection]`
        return if skip_secret_detection?

        logger.log_timed(LOG_MESSAGES[:secrets_check]) do
          # List all blobs via `ListAllBlobs()` based on the existence of a
          # quarantine directory. If no directory exists, we use `ListBlobs()` instead.
          blobs =
            if ignore_alternate_directories?
              all_blobs = project.repository.list_all_blobs(
                bytes_limit: BLOB_BYTES_LIMIT + 1,
                dynamic_timeout: logger.time_left,
                ignore_alternate_object_directories: true
              ).to_a

              # A quarantine directory would generally only contain objects which are actually new but
              # this is unfortunately not guaranteed by Git, so it might be that a push has objects which
              # already exist in the repository. To fix this, we have to filter the blobs that already exist.
              #
              # This is not a silver bullet though, a limitation of this is: a secret could possibly go into
              # a commit in a new branch (`refs/heads/secret`) that gets deleted later on, so the commit becomes
              # unreachable but it is still present in the repository, if the same secret is pushed in the same file
              # or even in a new file, it would be ignored because we filter the blob out because it still "exists".
              #
              # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136896#note_1680680116 for more details.
              filter_existing(all_blobs)
            else
              # We use `--not --all --not revisions` to ensure we only get new blobs.
              # TODO: explore using `with_paths: true` as an argument to load blob paths.
              project.repository.list_blobs(
                ['--not', '--all', '--not'] + revisions,
                bytes_limit: BLOB_BYTES_LIMIT + 1,
                dynamic_timeout: logger.time_left
              ).to_a
            end

          # Filter out larger than BLOB_BYTES_LIMIT blobs and binary blobs.
          blobs.reject! { |blob| blob.size > BLOB_BYTES_LIMIT || blob.binary }

          # Pass blobs to gem for scanning.
          response = ::Gitlab::SecretDetection::Scan
            .new(logger: secret_detection_logger)
            .secrets_scan(blobs, timeout: logger.time_left)

          # Handle the response depending on the status returned.
          format_response(response)

        # TODO: Perhaps have a separate message for each and better logging?
        rescue ::Gitlab::SecretDetection::Scan::RulesetParseError,
          ::Gitlab::SecretDetection::Scan::RulesetCompilationError => _
          secret_detection_logger.error(message: ERROR_MESSAGES[:scan_initialization_error])
        end
      end

      private

      def skip_secret_detection?
        changes_access.commits.any? { |commit| commit.safe_message =~ SPECIAL_COMMIT_FLAG }
      end

      def secret_detection_logger
        @secret_detection_logger ||= ::Gitlab::SecretDetectionLogger.build
      end

      def ignore_alternate_directories?
        git_env = ::Gitlab::Git::HookEnv.all(project.repository.gl_repository)
        git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
      end

      def filter_existing(blobs)
        # We check for object existence in the main repository, but the
        # object directory points to the object quarantine. This can be fixed
        # by unsetting it, which will cause us to use the normal repository as
        # indicated by its relative path again.
        gitaly_repo = project.repository.gitaly_repository.dup.tap { |repo| repo.git_object_directory = "" }

        map_blob_id_to_existence = project.repository.gitaly_commit_client.object_existence_map(
          blobs.map(&:id),
          gitaly_repo: gitaly_repo
        )

        # Remove blobs that already exist.
        blobs.reject { |blob| map_blob_id_to_existence[blob.id] }
      end

      def format_response(response)
        # Try to retrieve file path and commit sha for the blobs found.
        if [
          ::Gitlab::SecretDetection::Status::FOUND,
          ::Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS
        ].include?(response.status)
          # TODO: filter out revisions not related to found secrets
          results = transform_findings(response)
        end

        case response.status
        when ::Gitlab::SecretDetection::Status::NOT_FOUND
          # No secrets found, we log and skip the check.
          secret_detection_logger.info(message: LOG_MESSAGES[:secrets_not_found])
        when ::Gitlab::SecretDetection::Status::FOUND
          # One or more secrets found, generate message with findings and fail check.
          message = build_secrets_found_message(results)

          secret_detection_logger.info(message: LOG_MESSAGES[:found_secrets])

          raise ::Gitlab::GitAccess::ForbiddenError, message
        when ::Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS
          # One or more secrets found, but with scan errors, so we
          # generate a message with findings and errors, and fail the check.
          message = build_secrets_found_message(results, with_errors: true)

          secret_detection_logger.info(message: LOG_MESSAGES[:found_secrets_with_errors])

          raise ::Gitlab::GitAccess::ForbiddenError, message
        when ::Gitlab::SecretDetection::Status::SCAN_TIMEOUT
          # Entire scan timed out, we log and skip the check for now.
          secret_detection_logger.error(message: ERROR_MESSAGES[:scan_timeout_error])
        when ::Gitlab::SecretDetection::Status::INPUT_ERROR
          # Scan failed to invalid input. We skip the check because an input error
          # could be due to not having `blobs` being empty (i.e. no new blobs to scan).
          secret_detection_logger.error(message: ERROR_MESSAGES[:invalid_input_error])
        else
          # Invalid status returned by the scanning service/gem, we don't
          # know how to handle that, so nothing happens and we skip the check.
          secret_detection_logger.error(message: ERROR_MESSAGES[:invalid_scan_status_code_error])
        end
      end

      def revisions
        @revisions ||= changes_access
                        .changes
                        .pluck(:newrev) # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck
                        .reject { |revision| ::Gitlab::Git.blank_ref?(revision) }
                        .compact
      end

      def build_secrets_found_message(results, with_errors: false)
        message = with_errors ? LOG_MESSAGES[:found_secrets_with_errors] : LOG_MESSAGES[:found_secrets]

        results[:commits].each do |sha, paths|
          message += format(LOG_MESSAGES[:finding_message_occurrence_header], { sha: sha })

          paths.each do |path, findings|
            message += format(LOG_MESSAGES[:finding_message_occurrence_path], { path: path })

            findings.each do |finding|
              message += build_finding_message(finding, :commit)
            end
          end
        end

        results[:blobs].compact.each do |_, findings|
          findings.each do |finding|
            message += build_finding_message(finding, :blob)
          end
        end

        message += LOG_MESSAGES[:skip_secret_detection]
        message += LOG_MESSAGES[:found_secrets_post_message]
        message += format(
          LOG_MESSAGES[:found_secrets_docs_link],
          {
            path: Rails.application.routes.url_helpers.help_page_url(
              DOCUMENTATION_PATH,
              anchor: DOCUMENTATION_PATH_ANCHOR
            )
          }
        )

        message
      end

      def build_finding_message(finding, type)
        case finding.status
        when ::Gitlab::SecretDetection::Status::FOUND
          case type
          when :commit
            build_commit_finding_message(finding)
          when :blob
            build_blob_finding_message(finding)
          end
        when ::Gitlab::SecretDetection::Status::SCAN_ERROR
          format(ERROR_MESSAGES[:failed_to_scan_regex_error], finding.to_h)
        when ::Gitlab::SecretDetection::Status::BLOB_TIMEOUT
          format(ERROR_MESSAGES[:blob_timed_out_error], finding.to_h)
        end
      end

      def build_commit_finding_message(finding)
        format(
          LOG_MESSAGES[:finding_message_occurrence_line],
          {
            line_number: finding.line_number,
            description: finding.description
          }
        )
      end

      def build_blob_finding_message(finding)
        format(LOG_MESSAGES[:finding_message], finding.to_h)
      end

      def transform_findings(response)
        # Let's group the findings by the blob id.
        findings_by_blobs = response.results.group_by(&:blob_id)

        # We create an empty hash for the structure we'll create later as we pull out tree entries.
        findings_by_commits = {}

        # Let's create a set to store ids of blobs found in tree entries.
        blobs_found_with_tree_entries = Set.new

        # Scanning had found secrets, let's try to look up their file path and commit id. This can be done
        # by using `GetTreeEntries()` RPC, and cross examining blobs with ones where secrets where found.
        revisions.each do |revision|
          # We could try to handle pagination, but it is likely to timeout way earlier given the
          # huge default limit (100000) of entries, so we log an error if we get too many results.
          entries, cursor = ::Gitlab::Git::Tree.tree_entries(
            repository: project.repository,
            sha: revision,
            recursive: true,
            rescue_not_found: false
          )

          # TODO: Handle pagination in the upcoming iterations
          # We don't raise because we could still provide a hint to the user
          # about the detected secrets even without a commit sha/file path information.
          unless cursor.next_cursor.empty?
            secret_detection_logger.error(
              message: format(ERROR_MESSAGES[:too_many_tree_entries_error], { sha: revision })
            )
          end

          # Let's grab the `commit_id` and the `path` for that entry, we use the blob id as key.
          entries.each do |entry|
            # Skip any entry that isn't a blob.
            next if entry.type != :blob

            # Skip if the blob doesn't have any findings.
            next unless findings_by_blobs[entry.id].present?

            findings_by_commits.merge!(
              # Put findings with tree entries inside `findings_by_commits` hash.
              findings_by_blobs[entry.id].each_with_object({}) do |finding, hash|
                hash[entry.commit_id] ||= {}
                hash[entry.commit_id][entry.path] ||= []
                hash[entry.commit_id][entry.path] << finding
              end
            )

            # Mark as found with tree entry already.
            blobs_found_with_tree_entries << entry.id
          end
        end

        # Remove blobs that has already been found in a tree entry.
        findings_by_blobs.delete_if { |blob_id, _| blobs_found_with_tree_entries.include?(blob_id) }

        # Return the findings as a hash sorted by commits and blobs (minus ones already found).
        {
          commits: findings_by_commits,
          blobs: findings_by_blobs
        }
      end
    end
  end
end
