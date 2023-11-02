# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab Duo Chat QA Evaluation for Issue', :clean_gitlab_redis_chat, feature_category: :duo_chat do
  include Gitlab::Routing.url_helpers
  include ChatQaEvaluationHelpers

  describe 'evaluation', :real_ai_request, :saas do
    let_it_be(:user) { create(:user) }

    include_context 'with sample production epics and issues'

    before do
      stub_licensed_features(ai_features: true)
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_licensed_features(ai_tanuki_bot: true)

      root_group = issue.project.group.root_ancestor
      root_group.namespace_settings.update_attribute(:third_party_ai_features_enabled, true)
      root_group.namespace_settings.update_attribute(:experiment_features_enabled, true)
      root_group.add_owner(user)
      issue.project.add_developer(user)

      # Note: In SaaS simulation mode,
      # the url must be `https://gitlab.com` but the routing helper returns `localhost`
      # and breaks GitLab ReferenceExtractor
      stub_default_url_options(host: "gitlab.com", protocol: "https")
    end

    where(:question_template) do
      [
        ["what is this issue about?"],
        ["Summarize the comments into bullet points?"],
        ["Summarize with bullet points"],
        ["What are the unique use cases raised by commenters in this issue?"],
        ["Could you summarize this issue"],
        ["Summarize this Issue"],
        ["%<url>s - Summarize this issue"],
        ["What is the status of %<url>s?"],
        ["Please summarize the latest activity and current status of the issue %<url>s"],
        ["How can I improve the description of %<url>s " \
         "so that readers understand the value and problems to be solved?"],
        ["Please rewrite the description of %<url>s so that readers" \
         "understand the value and problems to be solved." \
         "Also add common \"jobs to be done\" or use cases which should be considered from a usability perspective."],
        ["Are there any open questions relating to this issue? %<url>s"]
      ]
    end

    with_them do
      where(:issue_id) do
        [
          [24652824], # https://gitlab.com/gitlab-org/gitlab/-/issues/17800
          [113414743], # https://gitlab.com/gitlab-org/gitlab/-/issues/371038
          [128440335], # https://gitlab.com/gitlab-org/gitlab/-/issues/412831
          [129393876], # https://gitlab.com/gitlab-org/gitlab/-/issues/415547
          [130125924], # https://gitlab.com/gitlab-org/gitlab/-/issues/416800
          [130193114] # https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34345
        ]
      end

      with_them do
        let(:issue) { Issue.find(issue_id) }
        let(:context) { issue.to_json }
        let(:url) { project_issue_url(issue.project, issue) }
        let(:question) { format(question_template, { url: url }) }

        it 'answers the question correctly' do
          evaluations = evaluate_without_reference(user, issue, question, context)[:evaluations]

          evaluations.each do |eval|
            expect(eval[:response]).to match(/Grade: CORRECT/i)
          end
        end
      end
    end
  end
end
