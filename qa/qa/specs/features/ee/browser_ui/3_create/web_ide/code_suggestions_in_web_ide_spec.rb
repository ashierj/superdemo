# frozen_string_literal: true

module QA
  # This test requires several feature flags, user settings, and instance configuration.
  # See https://docs.gitlab.com/ee/development/code_suggestions/#code-suggestions-development-setup
  RSpec.describe(
    'Create', :smoke, only: { pipeline: %i[staging staging-canary canary production] }, product_group: :ide
  ) do
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

      context 'when requesting code generation' do
        let(:prompt_data) { 'def reverse_string' }

        it 'returns a suggestion which can be accepted',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/425756' do
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

      context 'when requesting code completion' do
        let(:prompt_data) { "def set_name(whitespace_name)\n    this.name = whitespace_name." }

        it 'returns a suggestion which can be accepted',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/437111' do
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
    end
  end
end
