# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CiAction::Custom,
  :yaml_processor_feature_flag_corectness,
  feature_category: :security_policy_management do
  describe '#config' do
    subject { described_class.new(action, ci_variables, ci_context, 0).config }

    let_it_be(:ci_variables) do
      { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false', 'SECRET_DETECTION_DISABLED' => nil }
    end

    let(:ci_context) { Gitlab::Ci::Config::External::Context.new(user: user) }
    let(:user) { create(:user) }

    let(:ci_configuration) do
      <<~CI_CONFIG
      image: busybox:latest
      custom:
        stage: test
        script:
          - echo "Defined in security policy"
      CI_CONFIG
    end

    let(:action) { { scan: 'custom', ci_configuration: ci_configuration } }

    context 'with ci_configuration' do
      let(:action) { { scan: 'custom', ci_configuration: ci_configuration } }

      it do
        is_expected.to eq(
          {
            custom: {
              script: [
                "echo \"Defined in security policy\""
              ],
              stage: "test"
            },
            image: "busybox:latest"
          }
        )
      end

      context 'with invalid ci_configuration' do
        let(:ci_configuration) do
          <<~CI_CONFIG
          image: busybox:latest
          custom:
            stage: build
            script:
              - echo "Defined in security policy"
            sdfsdfsdfsdf
          CI_CONFIG
        end

        let(:expected_ci_config) do
          {
            'security-policy-ci-0': {
              'script' => "echo \"Error parsing security policy CI configuration: (<unknown>): could " \
                          "not find expected ':' while scanning a simple key at line 6 column 3\" && false",
              'allow_failure' => true
            }
          }
        end

        it { is_expected.to eq(expected_ci_config) }
      end

      context 'when including a file from a private project' do
        let(:project) do
          create(
            :project,
            :custom_repo,
            files: {
              'ci-file.yaml' => 'image: "busybox:latest"'
            }
          )
        end

        let(:ci_configuration) do
          <<~CI_CONFIG
          include:
            - project: #{project.full_path}
              file: ci-file.yaml
              ref: master
          CI_CONFIG
        end

        let(:action) { { scan: 'custom', ci_configuration: ci_configuration } }

        before do
          project.add_owner(user)
        end

        it { is_expected.to eq(image: 'busybox:latest') }
      end

      context 'when custom stages are defined' do
        let(:ci_configuration) do
          <<~CI_CONFIG
          stages:
            - custom_stage
          custom:
            stage: test
            script:
              - echo "Defined in security policy"
          CI_CONFIG
        end

        it 'removes custom stage definitions' do
          is_expected.to eq(
            {
              custom: {
                script: [
                  "echo \"Defined in security policy\""
                ],
                stage: "test"
              }
            }
          )
        end
      end

      context 'when the job is not assigned to a stage' do
        let(:ci_configuration) do
          <<~CI_CONFIG
          custom:
            script:
              - echo "Defined in security policy"
          CI_CONFIG
        end

        it 'will be assigned to the .pipeline-policy-test stage' do
          is_expected.to eq(
            {
              custom: {
                script: [
                  "echo \"Defined in security policy\""
                ],
                stage: ".pipeline-policy-test"
              }
            }
          )
        end
      end
    end

    context 'with ci_configuration_path' do
      let(:project) do
        create(
          :project,
          :custom_repo,
          :public,
          files: {
            'ci-file.yaml' => ci_configuration.to_s
          }
        )
      end

      let(:action) do
        {
          scan: 'custom',
          ci_configuration_path: { project: project.full_path, file: 'ci-file.yaml', ref: 'master' }
        }
      end

      it do
        is_expected.to eq(
          {
            custom: {
              script: [
                "echo \"Defined in security policy\""
              ],
              stage: "test"
            },
            image: "busybox:latest"
          }
        )
      end
    end

    context 'when project is private' do
      let(:project) do
        create(
          :project,
          :custom_repo,
          files: {
            'ci-file.yaml' => ci_configuration.to_s
          }
        )
      end

      let(:action) do
        {
          scan: 'custom',
          ci_configuration_path: { project: project.full_path, file: 'ci-file.yaml', ref: 'master' }
        }
      end

      before do
        project.add_owner(user)
      end

      it do
        is_expected.to eq(
          {
            custom: {
              script: [
                "echo \"Defined in security policy\""
              ],
              stage: "test"
            },
            image: "busybox:latest"
          }
        )
      end
    end
  end
end
