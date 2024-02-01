# frozen_string_literal: true

module QA
  # This test requires several feature flags, user settings, and instance configuration.
  # See https://docs.gitlab.com/ee/development/code_suggestions/#code-suggestions-development-setup
  RSpec.describe 'Create', product_group: :ide do
    describe 'Code Suggestions in Web IDE' do
      let(:project) { create(:project, :with_readme, name: 'webide-code-suggestions-project') }
      let(:file_name) { 'new_file.rb' }

      before do
        Flow::Login.sign_in

        create(:commit, project: project, actions: [
          { action: 'create', file_path: file_name, content: '# test' }
        ])

        project.visit!
        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::VSCode.perform(&:wait_for_ide_to_load)
      end

      shared_examples 'a code generation suggestion' do |testcase|
        let(:prompt_data) { 'def reverse_string' }

        it 'returns a code generation suggestion which can be accepted', testcase: testcase do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.add_prompt_into_a_file(file_name, prompt_data)
            previous_content_length = ide.editor_content_length
            previous_content_lines = ide.editor_content_lines

            # code generation will put suggestion on the next line
            ide.wait_for_code_suggestion
            expect(ide.editor_content_length).to be > previous_content_length, "Expected a suggestion"
            expect(ide.editor_content_lines).to be > previous_content_lines, "Expected additional lines in suggestion"

            ide.accept_code_suggestion
            expect(ide.editor_content_length).to be > previous_content_length, "Expected accepted suggestion in file"
            expect(ide.editor_content_lines).to be > previous_content_lines, "Expected additional lines in file"
          end
        end
      end

      shared_examples 'a code completion suggestion' do |testcase|
        # We should avoid the use of . in the prompt since the remote Selenium WebDriver
        # also uses send_keys to upload files if it finds the text matches a potential file name,
        # which can cause unintended behavior in the test.
        #
        # The remote WebDriver is used in orchestrated tests that make use of Selenoid video recording.
        # https://www.selenium.dev/documentation/webdriver/elements/file_upload/
        let(:prompt_data) { "def set_name(whitespace_name)\n    @name = " }

        it 'returns a code completion suggestion which can be accepted', testcase: testcase do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.add_prompt_into_a_file(file_name, prompt_data)
            previous_content_length = ide.editor_content_length
            previous_content_lines = ide.editor_content_lines

            # code completion will put suggestion on the same line
            ide.wait_for_code_suggestion
            expect(ide.editor_content_length).to be > previous_content_length, 'Expected a suggestion'
            expect(ide.editor_content_lines).to eq(previous_content_lines), 'Expected suggestion on same line'

            ide.accept_code_suggestion
            expect(ide.editor_content_length).to be > previous_content_length, 'Expected accepted suggestion in file'
            expect(ide.editor_content_lines).to eq(previous_content_lines), 'Expected suggestion on same line'
          end
        end
      end

      context 'on GitLab.com', :smoke, only: { pipeline: %i[staging staging-canary canary production] } do
        it_behaves_like 'a code generation suggestion',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/425756'

        it_behaves_like 'a code completion suggestion',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/437111'
      end

      context 'on Self-managed', :orchestrated, :ai_gateway do
        it_behaves_like 'a code completion suggestion',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/439625'
      end
    end
  end
end
