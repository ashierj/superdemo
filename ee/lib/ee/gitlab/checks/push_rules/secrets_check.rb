# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class SecretsCheck < ::Gitlab::Checks::BaseBulkChecker
          ERROR_MESSAGES = {
            failed_to_scan_regex_error: "\n-- Failed to scan blob(id: %{blob_id}) due to regex error.\n",
            blob_timed_out_error: "\n-- Scanning blob(id: %{blob_id}) timed out.\n",
            scan_timeout_error: 'Secret detection scan timed out.',
            scan_initialization_error: 'Secret detection scan failed to initialize.',
            invalid_input_error: 'Secret detection scan failed due to invalid input.',
            invalid_scan_status_code_error: 'Invalid secret detection scan status, check passed.',
            too_many_tree_entries_error: 'Too many tree entries exist for commit(sha: %{sha}).'
          }.freeze

          LOG_MESSAGES = {
            secrets_check: 'Detecting secrets...',
            secrets_not_found: 'Secret detection scan completed with no findings.',
            found_secrets: 'Secret detection scan completed with one or more findings.',
            found_secrets_post_message: "\n\nPlease remove the identified secrets in your commits and try again.",
            found_secrets_with_errors: 'Secret detection scan completed with one or more findings ' \
                                       'but some errors occured during the scan.',
            finding_message_occurrence: "\n\nSecret leaked in commit: %{sha}" \
                                        "\n  -- %{path}:%{line_number} | %{description}",
            finding_message: "\n\nSecret leaked in blob: %{blob_id}" \
                             "\n  -- line:%{line_number} | %{description}"
          }.freeze

          BLOB_BYTES_LIMIT = 1.megabyte # Limit is 1MiB to start with.

          def validate!
            # Return early and not perform the check if:
            #   1. unless application setting is enabled (regardless of whether it's a gitlab dedicated instance or not)
            #   2. feature flag is disabled for this project (when instance type is not gitlab dedicated)
            #   3. no push rule exist
            #   4. license is not ultimate
            return unless ::Gitlab::CurrentSettings.pre_receive_secret_detection_enabled

            return unless ::Gitlab::CurrentSettings.gitlab_dedicated_instance ||
              ::Feature.enabled?(:pre_receive_secret_detection_push_check, project)

            return unless push_rule && project.licensed_feature_available?(:pre_receive_secret_detection)

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
              collect_findings_occurrences(response)
            end

            case response.status
            when ::Gitlab::SecretDetection::Status::NOT_FOUND
              # No secrets found, we log and skip the check.
              secret_detection_logger.info(message: LOG_MESSAGES[:secrets_not_found])
            when ::Gitlab::SecretDetection::Status::FOUND
              # One or more secrets found, generate message with findings and fail check.
              message = build_secrets_found_message(response)

              secret_detection_logger.info(message: LOG_MESSAGES[:found_secrets])

              raise ::Gitlab::GitAccess::ForbiddenError, message
            when ::Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS
              # One or more secrets found, but with scan errors, so we
              # generate a message with findings and errors, and fail the check.
              message = build_secrets_found_with_errors_message(response)

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

          def build_secrets_found_message(response)
            message = LOG_MESSAGES[:found_secrets]

            response.results.each { |finding| message += build_finding_message(finding) }

            message += LOG_MESSAGES[:found_secrets_post_message]
            message
          end

          def build_secrets_found_with_errors_message(response)
            message = LOG_MESSAGES[:found_secrets_with_errors]

            response.results.each do |finding|
              case finding.status
              when ::Gitlab::SecretDetection::Status::FOUND
                message += build_finding_message(finding)
              when ::Gitlab::SecretDetection::Status::SCAN_ERROR
                message += format(ERROR_MESSAGES[:failed_to_scan_regex_error], finding.to_h)
              when ::Gitlab::SecretDetection::Status::BLOB_TIMEOUT
                message += format(ERROR_MESSAGES[:blob_timed_out_error], finding.to_h)
              end
            end

            message += LOG_MESSAGES[:found_secrets_post_message]
            message
          end

          def build_finding_message(finding)
            # If no occurrences are found, we display a more generic message (using blob id).
            return format(LOG_MESSAGES[:finding_message], finding.to_h) unless finding.occurrences.present?

            # If we have found the tree entries for those findings, let's display them.
            finding.occurrences.reduce('') do |message, occurrence|
              message + format(
                LOG_MESSAGES[:finding_message_occurrence],
                {
                  sha: occurrence[:sha],
                  path: occurrence[:path],
                  line_number: finding.line_number,
                  description: finding.description
                }
              )
            end
          end

          def collect_findings_occurrences(response)
            # Let's put aside the findings with secrets.
            findings_with_secrets = response
              .results
              .select { |finding| finding.status == ::Gitlab::SecretDetection::Status::FOUND }

            # Scanning had found secrets, let's try to look up their file path and commit id. This can be done
            # by using `GetTreeEntries()` RPC, and cross examining blobs with ones where secrets where found.
            revisions.each do |revision|
              # We could try to handle pagination, but it is likely to timeout way earlier given the
              # huge default limit (100000) of entries, so we log an error if we get too many results.
              entries, cursor = ::Gitlab::Git::Tree.tree_entries(project.repository, revision, nil, true, true, nil)

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

                # Update response with occurrences found.
                current_entry_finding = findings_with_secrets.find { |finding| finding.blob_id == entry.id }

                if current_entry_finding
                  current_entry_finding.occurrences ||= []
                  current_entry_finding.occurrences << { sha: entry.commit_id, path: entry.path }
                end
              end
            end
          end
        end
      end
    end
  end
end
