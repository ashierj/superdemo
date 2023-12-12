# frozen_string_literal: true

RSpec.shared_examples 'list and filter blobs' do
  # We cannot really get the same Gitlab::Git::Blob objects even if we call `list_all_blobs`
  # or `list_blobs` directly in the spec (which is perhaps also not a good idea) as the object
  # ids will always be different, so we expect the blobs to be an array with two objects of that kind.
  let(:old_blob) do
    have_attributes(
      class: Gitlab::Git::Blob,
      id: oldrev,
      size: 24
    )
  end

  let(:new_blob) do
    have_attributes(
      class: Gitlab::Git::Blob,
      id: newrev,
      size: 33
    )
  end

  context 'when quarantine directory exists' do
    let(:git_env) { { 'GIT_OBJECT_DIRECTORY_RELATIVE' => 'objects' } }
    let(:gitaly_commit_client) { instance_double(Gitlab::GitalyClient::CommitService) }

    before do
      allow(Gitlab::Git::HookEnv).to receive(:all).with(repository.gl_repository).and_return(git_env)

      # Since both blobs are committed to the repository, we mock the gitaly commit
      # client in such way that only the first is considered to exist in the repository.
      allow(repository).to receive(:gitaly_commit_client).and_return(gitaly_commit_client)
      allow(gitaly_commit_client).to receive(:object_existence_map).and_return(
        {
          oldrev.to_s => true,
          newrev.to_s => false
        }
      )
    end

    it 'lists all blobs of a repository' do
      expect(repository).to receive(:list_all_blobs)
        .with(
          bytes_limit: EE::Gitlab::Checks::PushRules::SecretsCheck::BLOB_BYTES_LIMIT + 1,
          dynamic_timeout: kind_of(Float),
          ignore_alternate_object_directories: true
        )
        .once
        .and_return(
          [old_blob, new_blob]
        )
        .and_call_original

      expect(subject.validate!).to be_truthy
    end

    it 'filters existing blobs out' do
      expect_next_instance_of(described_class) do |instance|
        # old blob is expected to be filtered out
        expect(instance).to receive(:filter_existing)
          .with(
            [old_blob, new_blob]
          )
          .once
          .and_return(new_blob)
          .and_call_original
      end

      expect(subject.validate!).to be_truthy
    end
  end

  context 'when quarantine directory does not exist' do
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

      expect(subject.validate!).to be_truthy
    end
  end
end
