# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::Completions::GenerateDescription, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:content) { 'issue submit button does not work' }
  let(:description_template_name) { nil }
  let(:ai_options) { { content: content, description_template_name: description_template_name } }
  let(:template_class) { ::Gitlab::Llm::Templates::GenerateDescription }
  let(:ai_response) { { completion: "Ai response." }.to_json }
  let(:uuid) { SecureRandom.uuid }
  let(:prompt_message) do
    build(:ai_message, :generate_description, user: user, resource: issuable, content: content, request_id: uuid)
  end

  let(:expected_template) { nil }

  subject(:generate_description) { described_class.new(prompt_message, template_class, ai_options).execute }

  RSpec.shared_examples 'description generation' do
    it 'executes a completion request and calls the response chains' do
      expect(::Gitlab::Llm::Templates::GenerateDescription).to receive(:new).with(content,
        template: expected_template).and_call_original
      expect_next_instance_of(::Gitlab::Llm::Anthropic::Client) do |instance|
        expect(instance).to receive(:complete).and_return(ai_response)
      end

      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).and_call_original

      expect(generate_description.response_body).to eq("Ai response.")
    end
  end

  describe "#execute" do
    context 'for an issue' do
      let_it_be(:issuable) { create(:issue, project: project) }

      it_behaves_like 'description generation'

      context 'with non-existent description template' do
        let(:description_template_name) { 'non-existent' }

        it_behaves_like 'description generation'
      end

      context 'with issue template' do
        let_it_be(:description_template_name) { 'project_issues_template' }
        let_it_be(:template_content) { "project_issues_template content" }
        let_it_be(:project) do
          template_files = {
            ".gitlab/issue_templates/#{description_template_name}.md" => template_content
          }
          create(:project, :custom_repo, files: template_files)
        end

        let_it_be(:issuable) { create(:issue, project: project) }

        let(:expected_template) { template_content }

        it_behaves_like 'description generation'
      end
    end

    context 'for a work item' do
      let_it_be(:issuable) { create(:work_item, :task, project: project) }

      it_behaves_like 'description generation'
    end

    context 'for a merge request' do
      let_it_be(:issuable) { create(:merge_request, source_project: project) }

      it_behaves_like 'description generation'
    end

    context 'for an epic' do
      let_it_be(:issuable) { create(:epic) }

      it_behaves_like 'description generation'
    end
  end
end
