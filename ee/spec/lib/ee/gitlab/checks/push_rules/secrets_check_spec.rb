# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRules::SecretsCheck, feature_category: :secret_detection do
  let_it_be(:user) { create(:user) }
  let_it_be(:push_rule) { create(:push_rule) }

  # Project is created with a custom repository, so
  # we create a README to have a blob committed already.
  let_it_be(:project) do
    create(
      :project,
      :custom_repo,
      files: { 'README' => 'Documentation goes here.' },
      push_rule: push_rule
    )
  end

  let_it_be(:repository) { project.repository }

  # Set revisions as follows:
  #   1. oldrev to commit created with the project above.
  #   2. newrev to commit created in before_all below.
  let(:oldrev) { '5e08a9ef8e7e257cbc727d6786bbc33ad7662625' }
  let(:newrev) { 'fe29d93da4843da433e62711ace82db601eb4f8f' }
  let(:changes) do
    [
      {
        oldrev: oldrev,
        newrev: newrev,
        ref: 'refs/heads/master'
      }
    ]
  end

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

  subject { described_class.new(changes_access) }

  before_all do
    project.add_developer(user)

    # Create a new commit to be used as the new revision in changes passed to secrets check.
    repository.commit_files(
      user,
      branch_name: 'add-dotenv-file',
      message: 'Add .env file',
      actions: [
        { action: :create, file_path: '.env', content: "SECRET=glpat-JUST20LETTERSANDNUMB" } # gitleaks:allow
      ]
    )
  end

  describe '#validate!' do
    it_behaves_like 'check ignored when push rule unlicensed'

    context 'when application settings is disabled' do
      before do
        Gitlab::CurrentSettings.update!(pre_receive_secret_detection_enabled: false)
      end

      it 'skips the check' do
        expect(subject.validate!).to be_nil
      end
    end

    context 'when application settings is enabled' do
      before do
        Gitlab::CurrentSettings.update!(pre_receive_secret_detection_enabled: true)
      end

      it_behaves_like 'use predefined push rules'

      context 'when instance is dedicated' do
        before do
          Gitlab::CurrentSettings.update!(gitlab_dedicated_instance: true)
        end

        context 'when license is not ultimate' do
          it 'skips the check' do
            expect(subject.validate!).to be_nil
          end
        end

        context 'when license is ultimate' do
          before do
            stub_licensed_features(pre_receive_secret_detection: true)
          end

          it_behaves_like 'list and filter blobs'
        end
      end

      context 'when instance is not dedicated' do
        before do
          Gitlab::CurrentSettings.update!(gitlab_dedicated_instance: false)
        end

        context 'when license is not ultimate' do
          it 'skips the check' do
            expect(subject.validate!).to be_nil
          end
        end

        context 'when license is ultimate' do
          before do
            stub_licensed_features(pre_receive_secret_detection: true)
          end

          it_behaves_like 'list and filter blobs'
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(pre_receive_secret_detection_push_check: false)
          end

          it 'skips the check' do
            expect(subject.validate!).to be_nil
          end
        end
      end
    end
  end
end
