# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :code_creation do
    include Support::API

    # These tests require several feature flags, user settings, and instance configurations.
    # See https://docs.gitlab.com/ee/development/code_suggestions/#code-suggestions-development-setup
    describe 'Code Suggestions' do
      # https://docs.gitlab.com/ee/api/code_suggestions.html#generate-code-completions-experiment
      shared_examples 'completions API with PAT auth' do |testcase|
        let(:expected_response_data) do
          {
            id: 'id',
            model: {
              engine: anything,
              name: anything,
              lang: expected_language
            },
            object: 'text_completion',
            created: anything
          }
        end

        it 'returns a suggestion', testcase: testcase do
          response = get_suggestion(prompt_data)

          expect_status_code(200, response)

          actual_response_data = parse_body(response)
          expect(actual_response_data).to match(a_hash_including(expected_response_data))

          suggestion = actual_response_data.dig(:choices, 0, :text)
          expect(suggestion.length).to be > 0, 'The suggestion should not be blank'
        end
      end

      shared_examples 'completions API with PAT auth using streaming' do |testcase|
        it 'streams a suggestion', testcase: testcase do
          response = get_suggestion(prompt_data)

          expect_status_code(200, response)

          expect(response.headers[:content_type].include?('event-stream')).to be_truthy, 'Expected an event stream'
          expect(response).not_to be_empty, 'Expected the first line of a stream'
        end
      end

      shared_examples 'unauthorized' do |testcase|
        it 'returns no suggestion', testcase: testcase do
          response = get_suggestion(prompt_data)

          expect_status_code(401, response)
        end
      end

      context 'when code completion is requested' do
        let(:prompt_data) do
          {
            prompt_version: 1,
            project_path: project_path,
            project_id: project_id,
            language_identifier: 'ruby',
            current_file: {
              file_name: '/test.rb',
              content_above_cursor: 'def set_name(whitespace_name)\n    this.name = whitespace_name.',
              content_below_cursor: '\nend'
            }
          }.compact
        end

        context 'on SaaS', only: { pipeline: %w[staging-canary staging canary production] } do
          let(:project_path) { 'gitlab-org/gitlab' }
          let(:project_id) { 278964 }
          let(:expected_language) { 'ruby' }

          it_behaves_like 'completions API with PAT auth', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/436992'
        end

        context 'on Self-managed', :orchestrated do
          let(:project_path) { nil }
          let(:project_id) { nil }

          context 'with a valid license' do
            context 'with a Duo Pro add-on' do
              context 'when seat is assigned', :ai_gateway do
                let(:expected_language) { 'ruby' }

                it_behaves_like 'completions API with PAT auth', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/436993'
              end
            end
          end

          context 'with no license', :ai_gateway_no_license do
            it_behaves_like 'unauthorized', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/446249'
          end
        end
      end

      context 'when code generation is requested' do
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

        context 'on SaaS', only: { pipeline: %w[staging-canary staging canary production] } do
          let(:project_path) { 'gitlab-org/gitlab' }
          let(:project_id) { 278964 }
          let(:expected_language) { 'python' }

          it_behaves_like 'completions API with PAT auth', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420973'
        end
      end

      context 'when streaming code suggestions' do
        let(:prompt_data) do
          {
            prompt_version: 1,
            project_path: project_path,
            project_id: project_id,
            current_file: {
              file_name: 'main.py',
              content_above_cursor: 'def reverse_string(s):\n    return s[::-1]\ndef test_empty_input_string()',
              content_below_cursor: ''
            },
            intent: 'generation',
            stream: true
          }.compact
        end

        context 'on SaaS', only: { pipeline: %w[staging-canary staging canary production] } do
          let(:project_path) { 'gitlab-org/gitlab' }
          let(:project_id) { 278964 }

          it_behaves_like 'completions API with PAT auth using streaming', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/436994'
        end
      end

      def get_suggestion(prompt_data)
        post(
          "#{Runtime::Scenario.gitlab_address}/api/v4/code_suggestions/completions",
          JSON.dump(prompt_data),
          headers: {
            Authorization: "Bearer #{Resource::PersonalAccessToken.fabricate!.token}",
            'Content-Type': 'application/json'
          }
        )
      end

      def expect_status_code(expected_code, response)
        expect(response).not_to be_nil
        expect(response.code).to be(expected_code), "Request returned (#{response.code}): `#{response}`"
      end
    end
  end
end
