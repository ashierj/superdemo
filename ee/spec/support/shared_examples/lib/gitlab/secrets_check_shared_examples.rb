# frozen_string_literal: true

RSpec.shared_examples 'scan passed' do
  include_context 'secrets check context'

  let(:passed_scan_response) { ::Gitlab::SecretDetection::Response.new(Gitlab::SecretDetection::Status::NOT_FOUND) }
  let(:new_blob_reference) { 'da66bef46dbf0ad7fdcbeec97c9eaa24c2846dda' }
  let(:new_blob) { have_attributes(class: Gitlab::Git::Blob, id: new_blob_reference, size: 24) }

  context 'with quarantine directory' do
    include_context 'quarantine directory exists'

    it 'lists all blobs of a repository' do
      expect(repository).to receive(:list_all_blobs)
        .with(
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float),
          ignore_alternate_object_directories: true
        )
        .once
        .and_return([old_blob, new_blob])
        .and_call_original

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: secrets_not_found)

      expect { subject.validate! }.not_to raise_error
    end

    it 'filters existing blobs out' do
      expect_next_instance_of(described_class) do |instance|
        # old blob is expected to be filtered out
        expect(instance).to receive(:filter_existing)
          .with(
            array_including(old_blob, new_blob)
          )
          .once
          .and_return(new_blob)
          .and_call_original
      end

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: secrets_not_found)

      expect { subject.validate! }.not_to raise_error
    end
  end

  context 'with no quarantine directory' do
    it 'list new blobs' do
      expect(repository).to receive(:list_blobs)
        .with(
          ['--not', '--all', '--not'] + changes.pluck(:newrev),
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float)
        )
        .once
        .and_return(new_blob)
        .and_call_original

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: secrets_not_found)

      expect { subject.validate! }.not_to raise_error
    end
  end

  it 'scans blobs' do
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .with(
          [new_blob],
          timeout: kind_of(Float)
        )
        .once
        .and_return(passed_scan_response)
        .and_call_original
    end

    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:format_response)
        .with(passed_scan_response)
        .once
        .and_call_original
    end

    expect(secret_detection_logger).to receive(:info)
      .once
      .with(message: secrets_not_found)

    expect { subject.validate! }.not_to raise_error
  end
end

RSpec.shared_examples 'scan detected secrets' do
  include_context 'secrets check context'

  let(:successful_scan_response) do
    ::Gitlab::SecretDetection::Response.new(
      Gitlab::SecretDetection::Status::FOUND,
      [
        Gitlab::SecretDetection::Finding.new(
          new_blob_reference,
          Gitlab::SecretDetection::Status::FOUND,
          1,
          "gitlab_personal_access_token",
          "GitLab Personal Access Token"
        )
      ]
    )
  end

  # The new commit must have a secret, so create a commit with one.
  let_it_be(:new_commit) { create_commit('.env' => 'SECRET=glpat-JUST20LETTERSANDNUMB') } # gitleaks:allow

  context 'with quarantine directory' do
    include_context 'quarantine directory exists'

    it 'lists all blobs of a repository' do
      expect(repository).to receive(:list_all_blobs)
        .with(
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float),
          ignore_alternate_object_directories: true
        )
        .once
        .and_return([old_blob, new_blob])
        .and_call_original

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets)

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end

    it 'filters existing blobs out' do
      expect_next_instance_of(described_class) do |instance|
        # old blob is expected to be filtered out
        expect(instance).to receive(:filter_existing)
          .with(
            array_including(old_blob, new_blob)
          )
          .once
          .and_return(new_blob)
          .and_call_original
      end

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets)

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end
  end

  context 'with no quarantine directory' do
    it 'list new blobs' do
      expect(repository).to receive(:list_blobs)
        .with(
          ['--not', '--all', '--not'] + changes.pluck(:newrev),
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float)
        )
        .once
        .and_return(new_blob)
        .and_call_original

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets)

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end
  end

  it 'scans blobs' do
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .with(
          [new_blob],
          timeout: kind_of(Float)
        )
        .once
        .and_return(successful_scan_response)
        .and_call_original
    end

    expect(secret_detection_logger).to receive(:info)
      .once
      .with(message: found_secrets)

    expect { subject.validate! }.to raise_error do |error|
      expect(error).to be_a(::Gitlab::GitAccess::ForbiddenError)
      expect(error.message).to include(found_secrets)
      expect(error.message).to include(found_message_occurrence)
      expect(error.message).to include(skip_secret_detection)
      expect(error.message).to include(found_secrets_post_message)
    end
  end

  it 'loads tree entries of the new commit' do
    expect(::Gitlab::Git::Tree).to receive(:tree_entries)
      .once
      .with(repository, new_commit, nil, true, true, nil)
      .and_return([tree_entries, gitaly_pagination_cursor])
      .and_call_original

    expect(secret_detection_logger).to receive(:info)
      .once
      .with(message: found_secrets)

    expect { subject.validate! }.to raise_error do |error|
      expect(error).to be_a(::Gitlab::GitAccess::ForbiddenError)
      expect(error.message).to include(found_secrets)
      expect(error.message).to include(found_message_occurrence)
      expect(error.message).to include(skip_secret_detection)
      expect(error.message).to include(found_secrets_post_message)
    end
  end

  context 'when no tree entries exist or cannot be loaded' do
    it 'gracefully raises an error with existing information' do
      expect(::Gitlab::Git::Tree).to receive(:tree_entries)
        .once
        .with(repository, new_commit, nil, true, true, nil)
        .and_return([{}, gitaly_pagination_cursor])

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets)

      expect { subject.validate! }.to raise_error do |error|
        expect(error).to be_a(::Gitlab::GitAccess::ForbiddenError)
        expect(error.message).to include(found_secrets)
        expect(error.message).to include(found_message)
        expect(error.message).to include(found_secrets_post_message)
      end
    end
  end

  context 'when tree has too many entries' do
    let(:gitaly_pagination_cursor) { Gitaly::PaginationCursor.new(next_cursor: "abcdef") }

    it 'logs an error and continue to raise and present findings' do
      expect(::Gitlab::Git::Tree).to receive(:tree_entries)
        .once
        .with(repository, new_commit, nil, true, true, nil)
        .and_return([tree_entries, gitaly_pagination_cursor])

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets)

      expect(secret_detection_logger).to receive(:error)
        .once
        .with(message: error_messages[:too_many_tree_entries_error])

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end
  end

  context 'when new commit has file in subdirectory' do
    let_it_be(:new_commit) { create_commit('config/.env' => 'SECRET=glpat-JUST20LETTERSANDNUMB') } # gitleaks:allow

    let(:found_secret_path) { 'config/.env' }
    let(:tree_entries) do
      [
        Gitlab::Git::Tree.new(
          id: new_blob_reference,
          type: :blob,
          mode: '100644',
          name: '.env',
          path: 'config/.env',
          flat_path: 'config/.env',
          commit_id: new_commit
        )
      ]
    end

    it 'loads tree entries of the new commit in subdirectories' do
      expect(::Gitlab::Git::Tree).to receive(:tree_entries)
        .once
        .with(repository, new_commit, nil, true, true, nil)
        .and_return([tree_entries, gitaly_pagination_cursor])
        .and_call_original

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets)

      expect { subject.validate! }.to raise_error do |error|
        expect(error).to be_a(::Gitlab::GitAccess::ForbiddenError)
        expect(error.message).to include(found_secrets)
        expect(error.message).to include(found_message_occurrence)
        expect(error.message).to include(skip_secret_detection)
        expect(error.message).to include(found_secrets_post_message)
      end
    end
  end
end

RSpec.shared_examples 'scan detected secrets but some errors occured' do
  include_context 'secrets check context'

  let(:successful_scan_with_errors_response) do
    ::Gitlab::SecretDetection::Response.new(
      Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS,
      [
        Gitlab::SecretDetection::Finding.new(
          new_blob_reference,
          Gitlab::SecretDetection::Status::FOUND,
          1,
          "gitlab_personal_access_token",
          "GitLab Personal Access Token"
        ),
        Gitlab::SecretDetection::Finding.new(
          timed_out_blob_reference,
          Gitlab::SecretDetection::Status::BLOB_TIMEOUT
        ),
        Gitlab::SecretDetection::Finding.new(
          failed_to_scan_blob_reference,
          Gitlab::SecretDetection::Status::SCAN_ERROR
        )
      ]
    )
  end

  let_it_be(:new_commit) { create_commit('.env' => 'SECRET=glpat-JUST20LETTERSANDNUMB') } # gitleaks:allow
  let_it_be(:timed_out_commit) { create_commit('.test.env' => 'TOKEN=glpat-JUST20LETTERSANDNUMB') } # gitleaks:allow
  let_it_be(:failed_to_scan_commit) { create_commit('.dev.env' => 'GLPAT=glpat-JUST20LETTERSANDNUMB') } # gitleaks:allow

  let(:changes) do
    [
      { oldrev: initial_commit, newrev: new_commit, ref: 'refs/heads/master' },
      { oldrev: initial_commit, newrev: timed_out_commit, ref: 'refs/heads/master' },
      { oldrev: initial_commit, newrev: failed_to_scan_commit, ref: 'refs/heads/master' }
    ]
  end

  let(:timed_out_blob_reference) { 'eaf3c09526f50b5e35a096ef70cca033f9974653' }
  let(:failed_to_scan_blob_reference) { '4fbec77313fd240d00fc37e522d0274b8fb54bd1' }

  let(:timed_out_blob) { have_attributes(class: Gitlab::Git::Blob, id: timed_out_blob_reference, size: 32) }
  let(:failed_to_scan_blob) { have_attributes(class: Gitlab::Git::Blob, id: failed_to_scan_blob_reference, size: 32) }

  # Used for the quarantine directory context below.
  let(:object_existence_map) do
    {
      old_blob_reference.to_s => true,
      new_blob_reference.to_s => false,
      timed_out_blob_reference.to_s => false,
      failed_to_scan_blob_reference.to_s => false
    }
  end

  context 'with quarantine directory' do
    include_context 'quarantine directory exists'

    it 'lists all blobs of a repository' do
      expect(repository).to receive(:list_all_blobs)
        .with(
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float),
          ignore_alternate_object_directories: true
        )
        .once
        .and_return(
          [old_blob, new_blob, timed_out_blob, failed_to_scan_blob]
        )
        .and_call_original

      expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
        expect(instance).to receive(:secrets_scan)
          .with(
            array_including(new_blob, timed_out_blob, failed_to_scan_blob),
            timeout: kind_of(Float)
          )
          .and_return(successful_scan_with_errors_response)
      end

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets_with_errors)

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end

    it 'filters existing blobs out' do
      expect_next_instance_of(described_class) do |instance|
        # old blob is expected to be filtered out
        expect(instance).to receive(:filter_existing)
          .with(
            array_including(old_blob, new_blob, timed_out_blob, failed_to_scan_blob)
          )
          .once
          .and_return(
            array_including(new_blob, timed_out_blob, failed_to_scan_blob)
          )
          .and_call_original
      end

      expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
        expect(instance).to receive(:secrets_scan)
          .with(
            array_including(new_blob, timed_out_blob, failed_to_scan_blob),
            timeout: kind_of(Float)
          )
          .and_return(successful_scan_with_errors_response)
      end

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets_with_errors)

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end
  end

  context 'with no quarantine directory' do
    it 'list new blobs' do
      expect(repository).to receive(:list_blobs)
        .with(
          ['--not', '--all', '--not'] + changes.pluck(:newrev),
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float)
        )
        .once
        .and_return(
          array_including(new_blob, old_blob, timed_out_blob, failed_to_scan_blob)
        )
        .and_call_original

      expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
        expect(instance).to receive(:secrets_scan)
          .with(
            array_including(new_blob, timed_out_blob, failed_to_scan_blob),
            timeout: kind_of(Float)
          )
          .and_return(successful_scan_with_errors_response)
      end

      expect(secret_detection_logger).to receive(:info)
        .once
        .with(message: found_secrets_with_errors)

      expect { subject.validate! }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
    end
  end

  it 'scans blobs' do
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .with(
          array_including(new_blob, timed_out_blob, failed_to_scan_blob),
          timeout: kind_of(Float)
        )
        .once
        .and_return(successful_scan_with_errors_response)
    end

    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:format_response)
      .with(successful_scan_with_errors_response)
      .once
      .and_call_original
    end

    expect(secret_detection_logger).to receive(:info)
      .once
      .with(message: found_secrets_with_errors)

    expect { subject.validate! }.to raise_error do |error|
      expect(error).to be_a(::Gitlab::GitAccess::ForbiddenError)
      expect(error.message).to include(found_secrets_with_errors)
      expect(error.message).to include(found_message_occurrence)
      expect(error.message).to include(blob_timed_out_error)
      expect(error.message).to include(failed_to_scan_regex_error)
      expect(error.message).to include(skip_secret_detection)
      expect(error.message).to include(found_secrets_post_message)
    end
  end

  it 'loads tree entries of the new commit' do
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .with(
          array_including(new_blob, timed_out_blob, failed_to_scan_blob),
          timeout: kind_of(Float)
        )
        .once
        .and_return(successful_scan_with_errors_response)
    end

    expect(::Gitlab::Git::Tree).to receive(:tree_entries)
      .with(repository, new_commit, nil, true, true, nil)
      .once
      .ordered
      .and_return([tree_entries, gitaly_pagination_cursor])
      .and_call_original

    expect(::Gitlab::Git::Tree).to receive(:tree_entries)
      .with(repository, timed_out_commit, nil, true, true, nil)
      .once
      .ordered
      .and_return([[], nil])
      .and_call_original

    expect(::Gitlab::Git::Tree).to receive(:tree_entries)
      .with(repository, failed_to_scan_commit, nil, true, true, nil)
      .once
      .ordered
      .and_return([[], nil])
      .and_call_original

    expect(secret_detection_logger).to receive(:info)
      .once
      .with(message: found_secrets_with_errors)

    expect { subject.validate! }.to raise_error do |error|
      expect(error).to be_a(::Gitlab::GitAccess::ForbiddenError)
      expect(error.message).to include(found_secrets_with_errors)
      expect(error.message).to include(found_message_occurrence)
      expect(error.message).to include(blob_timed_out_error)
      expect(error.message).to include(failed_to_scan_regex_error)
      expect(error.message).to include(skip_secret_detection)
      expect(error.message).to include(found_secrets_post_message)
    end
  end
end

RSpec.shared_examples 'scan timed out' do
  include_context 'secrets check context'

  let(:scan_timed_out_scan_response) do
    ::Gitlab::SecretDetection::Response.new(Gitlab::SecretDetection::Status::SCAN_TIMEOUT)
  end

  it 'logs the error and passes the check' do
    # Mock the response to return a scan timed out status.
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .and_return(scan_timed_out_scan_response)
    end

    # Error bubbles up from scan class and is handled in secrets check.
    expect(secret_detection_logger).to receive(:error)
      .once
      .with(message: error_messages[:scan_timeout_error])

    expect { subject.validate! }.not_to raise_error
  end
end

RSpec.shared_examples 'scan failed to initialize' do
  include_context 'secrets check context'

  before do
    # Intentionally set `RULESET_FILE_PATH` to an incorrect path to cause error.
    stub_const('::Gitlab::SecretDetection::Scan::RULESET_FILE_PATH', 'gitleaks.toml')
  end

  it 'logs the error and passes the check' do
    # File parsing error is written to the logger.
    expect(secret_detection_logger).to receive(:error)
      .once
      .with(
        "Failed to parse secret detection ruleset from 'gitleaks.toml' path: " \
        "No such file or directory @ rb_sysopen - gitleaks.toml"
      )

    # Error bubbles up from scan class and is handled in secrets check.
    expect(secret_detection_logger).to receive(:error)
      .once
      .with(message: error_messages[:scan_initialization_error])

    expect { subject.validate! }.not_to raise_error
  end
end

RSpec.shared_examples 'scan failed with invalid input' do
  include_context 'secrets check context'

  let(:failed_with_invalid_input_response) do
    ::Gitlab::SecretDetection::Response.new(::Gitlab::SecretDetection::Status::INPUT_ERROR)
  end

  it 'logs the error and passes the check' do
    # Mock the response to return a scan invalid input status.
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .and_return(failed_with_invalid_input_response)
    end

    # Error bubbles up from scan class and is handled in secrets check.
    expect(secret_detection_logger).to receive(:error)
      .once
      .with(message: error_messages[:invalid_input_error])

    expect { subject.validate! }.not_to raise_error
  end
end

RSpec.shared_examples 'scan skipped due to invalid status' do
  include_context 'secrets check context'

  let(:invalid_scan_status_code) { 7 } # doesn't exist in ::Gitlab::SecretDetection::Status
  let(:invalid_scan_status_code_response) { ::Gitlab::SecretDetection::Response.new(invalid_scan_status_code) }

  it 'logs the error and passes the check' do
    # Mock the response to return a scan invalid status.
    expect_next_instance_of(::Gitlab::SecretDetection::Scan) do |instance|
      expect(instance).to receive(:secrets_scan)
        .and_return(invalid_scan_status_code_response)
    end

    # Error bubbles up from scan class and is handled in secrets check.
    expect(secret_detection_logger).to receive(:error)
      .once
      .with(message: error_messages[:invalid_scan_status_code_error])

    expect { subject.validate! }.not_to raise_error
  end
end

RSpec.shared_examples 'scan skipped when a commit has special bypass flag' do
  include_context 'secrets check context'

  let_it_be(:new_commit) do
    create_commit(
      { '.env' => 'SECRET=glpat-JUST20LETTERSANDNUMB' }, # gitleaks:allow
      'dummy commit [skip secret detection]'
    )
  end

  it 'skips the scanning process' do
    expect { subject.validate! }.not_to raise_error
  end

  context 'when other commits having secrets in the same push' do
    let_it_be(:second_commit_with_secret) do
      create_commit('.test.env' => 'TOKEN=glpat-JUST20LETTERSANDNUMB') # gitleaks:allow
    end

    let(:changes) do
      [
        { oldrev: initial_commit, newrev: new_commit, ref: 'refs/heads/master' },
        { oldrev: initial_commit, newrev: second_commit_with_secret, ref: 'refs/heads/master' }
      ]
    end

    it 'skips the scanning process still' do
      expect { subject.validate! }.not_to raise_error
    end
  end
end
