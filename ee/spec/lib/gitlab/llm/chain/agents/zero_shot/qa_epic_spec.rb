# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab Duo Chat QA Evaluation for Epic', :clean_gitlab_redis_chat, feature_category: :duo_chat do
  include Gitlab::Routing.url_helpers
  include ChatQaEvaluationHelpers

  describe 'evaluation', :real_ai_request, :saas do
    let_it_be(:user) { create(:user) }

    include_context 'with sample production epics and issues'

    before do
      stub_licensed_features(ai_features: true)
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_licensed_features(ai_tanuki_bot: true)

      stub_licensed_features(epics: true)
      root_group = epic.group.root_ancestor
      root_group.namespace_settings.update_attribute(:experiment_features_enabled, true)
      root_group.add_owner(user)
    end

    where(:question_template) do
      [
        ["Summarize the comments into bullet points?"],
        ["Summarize with bullet points"],
        ["Can you create a simpler list of which questions a user should be able to ask according to this epic."],
        ["Summarize this Epic."],
        ["How much work is left to be done %<url>s?"],
        ["How much work is left to be done in this epic?"],
        ["Please summarize what the objective and next steps are for %<url>s"]
      ]
    end

    with_them do
      where(:epic_id) do
        [
          [822061], # https://gitlab.com/groups/gitlab-org/-/epics/10550
          [835460], # https://gitlab.com/groups/gitlab-org/-/epics/10694
          [854759] # https://gitlab.com/groups/gitlab-org/-/epics/10814
        ]
      end

      with_them do
        let(:epic) { Epic.find(epic_id) }
        let(:context) { epic.to_json }
        let(:url) { group_epic_url(epic.group, epic) }
        let(:question) { format(question_template, { url: url }) }

        it 'answers the question correctly' do
          evaluations = evaluate_without_reference(user, epic, question, context)[:evaluations]

          evaluations.each do |eval|
            expect(eval[:response]).to match(/Grade: CORRECT/i)
          end
        end
      end
    end
  end
end
