# frozen_string_literal: true

RSpec.shared_context 'secrets check context' do
  include_context 'secret detection error and log messages context'

  let_it_be(:user) { create(:user) }

  # Project is created with an empty repository, so
  # we create an initial commit to have a blob committed.
  let_it_be(:project) { create(:project, :empty_repo, push_rule: push_rule) }
  let_it_be(:repository) { project.repository }
  let_it_be(:initial_commit) do
    # An initial commit to use as the oldrev in `changes` object below.
    repository.commit_files(
      user,
      branch_name: 'master',
      message: 'Initial commit',
      actions: [
        { action: :create, file_path: 'README', content: 'Documentation goes here' }
      ]
    )
  end

  # Create a default `new_commit` for use cases in which we don't care much about blobs.
  let_it_be(:new_commit) { create_commit('.env' => 'BASE_URL=https://foo.bar') }

  # Define blob references as follows:
  #   1. old reference is used as the blob id for the initial commit.
  #   2. new reference is used as the blob id for commits created in before_all statements elsewhere.
  let(:old_blob_reference) { 'f3ac5ae18d057a11d856951f27b9b5b8043cf1ec' }
  let(:new_blob_reference) { 'fe29d93da4843da433e62711ace82db601eb4f8f' }
  let(:changes) do
    [
      {
        oldrev: initial_commit,
        newrev: new_commit,
        ref: 'refs/heads/master'
      }
    ]
  end

  # Set up the `changes_access` object to use below.
  let(:protocol) { 'ssh' }
  let(:timeout) { Gitlab::GitAccess::INTERNAL_TIMEOUT }
  let(:logger) { Gitlab::Checks::TimedLogger.new(timeout: timeout) }
  let(:user_access) { Gitlab::UserAccess.new(user, container: project) }
  let(:changes_access) do
    Gitlab::Checks::ChangesAccess.new(
      changes,
      project: project,
      user_access: user_access,
      protocol: protocol,
      logger: logger
    )
  end

  # We cannot really get the same Gitlab::Git::Blob objects even if we call `list_all_blobs` or `list_blobs`
  # directly in any of the specs (which is also not a very good idea) as the object ids will always
  # be different, so we expect the attributes of the returned object to match.
  let(:old_blob) { have_attributes(class: Gitlab::Git::Blob, id: old_blob_reference, size: 23) }
  let(:new_blob) { have_attributes(class: Gitlab::Git::Blob, id: new_blob_reference, size: 33) }

  # Used for mocking calls to logger.
  let(:secret_detection_logger) { instance_double(::Gitlab::SecretDetectionLogger) }

  before do
    allow(::Gitlab::SecretDetectionLogger).to receive(:build).and_return(secret_detection_logger)
  end

  before_all do
    project.add_developer(user)
  end

  subject(:secrets_check) { described_class.new(changes_access) }
end

RSpec.shared_context 'secret detection error and log messages context' do
  # Error messsages
  let(:failed_to_scan_regex_error) do
    format(
      "\n-- Failed to scan blob(id: %{blob_id}) due to regex error.\n",
      { blob_id: failed_to_scan_blob_reference }
    )
  end

  let(:blob_timed_out_error) do
    format(
      "\n-- Scanning blob(id: %{blob_id}) timed out.\n",
      { blob_id: timed_out_blob_reference }
    )
  end

  let(:error_messages) do
    {
      scan_timeout_error: 'Secret detection scan timed out.',
      scan_initialization_error: 'Secret detection scan failed to initialize.',
      invalid_input_error: 'Secret detection scan failed due to invalid input.',
      invalid_scan_status_code_error: 'Invalid secret detection scan status, check passed.'
    }
  end

  # Log messages
  let(:secrets_not_found) { 'Secret detection scan completed with no findings.' }
  let(:found_secrets) { 'Secret detection scan completed with one or more findings.' }
  let(:found_secrets_post_message) { "\n\nPlease remove the identified secrets in your commits and try again." }
  let(:found_secrets_with_errors) do
    'Secret detection scan completed with one or more findings but some errors occured during the scan.'
  end

  let(:found_secret_line_number) { '1' }
  let(:found_secret_type) { 'gitlab_personal_access_token' }
  let(:found_secret_description) { 'GitLab Personal Access Token' }

  let(:found_secrets_message) do
    message = <<~MESSAGE
      \nBlob id: %{found_secret_blob_id}
      -- Line: %{found_secret_line_number}
      -- Type: %{found_secret_type}
      -- Description: %{found_secret_description}\n
    MESSAGE

    format(
      message,
      {
        found_secret_blob_id: new_blob_reference,
        found_secret_line_number: found_secret_line_number,
        found_secret_type: found_secret_type,
        found_secret_description: found_secret_description
      }
    )
  end
end

RSpec.shared_context 'quarantine directory exists' do
  let(:git_env) { { 'GIT_OBJECT_DIRECTORY_RELATIVE' => 'objects' } }
  let(:gitaly_commit_client) { instance_double(Gitlab::GitalyClient::CommitService) }

  let(:object_existence_map) do
    {
      old_blob_reference.to_s => true,
      new_blob_reference.to_s => false
    }
  end

  before do
    allow(Gitlab::Git::HookEnv).to receive(:all).with(repository.gl_repository).and_return(git_env)

    # Since all blobs are committed to the repository, we mock the gitaly commit
    # client and `object_existence_map` in such way only some of them are considered new.
    allow(repository).to receive(:gitaly_commit_client).and_return(gitaly_commit_client)
    allow(gitaly_commit_client).to receive(:object_existence_map).and_return(object_existence_map)
  end
end

def create_commit(blobs)
  commit = repository.commit_files(
    user,
    branch_name: 'a-new-branch',
    message: 'Add a file',
    actions: blobs.map do |path, content|
      {
        action: :create,
        file_path: path,
        content: content
      }
    end
  )

  # `list_blobs` only returns unreferenced blobs because it is used for hooks, so we have
  # to delete the branch since Gitaly does not allow us to create loose objects via the RPC.
  repository.delete_branch('a-new-branch')

  commit
end
