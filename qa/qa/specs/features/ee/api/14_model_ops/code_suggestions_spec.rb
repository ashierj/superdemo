# frozen_string_literal: true

module QA
  RSpec.describe 'ModelOps', product_group: :code_creation do
    include Support::API

    describe 'Code Suggestions' do
      let(:prompt_data) do
        {
          prompt_version: 1,
          project_path: project_path,
          project_id: project_id,
          current_file: {
            file_name: 'main.py',
            content_above_cursor: 'def reverse_string(s):\n    return s[::-1]\ndef test_empty_input_string()',
            content_below_cursor: ''
          }
        }.compact
      end

      let(:expected_response_data) do
        {
          id: 'id',
          model: {
            engine: anything,
            name: anything,
            lang: 'python'
          },
          object: 'text_completion',
          created: anything
        }
      end

      # https://docs.gitlab.com/ee/api/code_suggestions.html#generate-code-completions-experiment
      shared_examples 'completions API with PAT auth' do |testcase|
        it 'returns a suggestion', testcase: testcase do
          response = post(
            "#{Runtime::Scenario.gitlab_address}/api/v4/code_suggestions/completions",
            JSON.dump(prompt_data),
            headers: {
              Authorization: "Bearer #{Resource::PersonalAccessToken.fabricate!.token}",
              'Content-Type': 'application/json'
            }
          )

          expect(response).not_to be_nil
          expect(response.code).to be(200), "Request returned (#{response.code}): `#{response}`"

          actual_response_data = parse_body(response)
          expect(actual_response_data).to match(a_hash_including(expected_response_data))
          expect(actual_response_data.dig(:choices, 0, :text).length).to be > 0, 'The suggestion should not be blank'
        end
      end

      # This test requires several feature flags, user settings, and instance configuration.
      # See https://docs.gitlab.com/ee/development/code_suggestions/#code-suggestions-development-setup
      context 'on SaaS', only: { pipeline: %w[staging-canary staging canary production] } do
        let(:project_path) { 'gitlab-org/gitlab' }
        let(:project_id) { 278964 }

        it_behaves_like 'completions API with PAT auth',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420973'
      end

      context 'on Self-managed', :orchestrated, :ai_gateway, quarantine: {
        type: :investigating,
        issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/436465'
      } do
        let(:project_path) { nil }
        let(:project_id) { nil }

        it_behaves_like 'completions API with PAT auth',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/435227'
      end
    end
  end
end
