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
      let(:prompt_data) { 'def reverse_string' }
      let(:prompt_regex) { /\.reverse/ }

      before do
        Flow::Login.sign_in

        create(:commit, project: project, actions: [
          { action: 'create', file_path: file_name, content: '# test' }
        ])

        project.visit!
        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::VSCode.perform(&:wait_for_ide_to_load)
      end

      it 'adds text into a file and verifies code suggestions appear',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/425756' do
        Page::Project::WebIDE::VSCode.perform do |ide|
          ide.add_prompt_into_a_file(file_name, prompt_data)
          ide.verify_prompt_appears_and_accept(prompt_regex)

          expect(ide.validate_prompt(prompt_regex)).to eq true
        end
      end
    end
  end
end
