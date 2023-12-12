# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class SecretsCheck < ::Gitlab::Checks::BaseBulkChecker
          BLOB_BYTES_LIMIT = 1.megabyte # Limit is 1MiB to start with.

          LOG_MESSAGE = "Detecting secrets..."

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

            logger.log_timed(LOG_MESSAGE) do
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
                  revisions = changes_access
                    .changes
                    .pluck(:newrev) # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck
                    .reject { |revision| ::Gitlab::Git.blank_ref?(revision) }
                    .compact

                  # We add `--not --all --not revisions` to ensure we only get new blobs.
                  project.repository.list_blobs(
                    ['--not', '--all', '--not'] + revisions,
                    bytes_limit: BLOB_BYTES_LIMIT + 1,
                    dynamic_timeout: logger.time_left
                  ).to_a
                end

              # Filter out larger than BLOB_BYTES_LIMIT blobs and binary blobs.
              blobs.reject! { |blob| blob.size > BLOB_BYTES_LIMIT || blob.binary }
            end
          end

          private

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
        end
      end
    end
  end
end
