# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatQaEvaluationHelpers, feature_category: :duo_chat do
  include described_class

  describe 'evaluation without reference answer', :clean_gitlab_redis_chat, :real_ai_request, :saas do
    let_it_be_with_reload(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) do
      create(:issue, project: project, title: 'A testing issue for AI reliability',
        description: 'This issue is about evaluating reliability of various AI providers.')
    end

    let(:question) { "Summarize this issue" }

    before_all do
      group.add_owner(user)
    end

    before do
      stub_licensed_features(ai_features: true)
      stub_ee_application_setting(should_check_namespace_plan: true)

      group.namespace_settings.update!(
        experiment_features_enabled: true
      )

      stub_licensed_features(ai_tanuki_bot: true)
    end

    context 'when the qa evaluation helper is fed the correct issue data' do
      it 'evaluates as correct' do
        result = evaluate_without_reference(user, issue, question, issue.to_json)

        result[:evaluations].each do |eval|
          expect(eval[:response]).to match(/Grade: CORRECT/i)
        end

        expect(result[:tools_used]).to match([Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor,
          Gitlab::Llm::Chain::Tools::JsonReader::Executor])
      end
    end

    context 'when the qa evaluation helper is fed an incorrect issue data' do
      # Duo chat answers the question based on `issue`
      # The evaluator's given the context `issue` with different title and description
      it 'evaluates as incorrect' do
        modified_issue_context = issue.attributes
        modified_issue_context["title"] = "Cloud provider's reliability"
        modified_issue_context["description"] = 'This issue is about the reliability of various cloud providers.'

        evaluations = evaluate_without_reference(user, issue, question, modified_issue_context.to_json)[:evaluations]
        evaluations.each do |eval|
          expect(eval[:response]).to match(/Grade: INCORRECT/i)
        end
      end
    end
  end
end
