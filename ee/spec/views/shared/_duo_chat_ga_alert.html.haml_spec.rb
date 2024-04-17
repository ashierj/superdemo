# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_duo_chat_ga_alert', :saas, feature_category: :code_suggestions do
  let(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate -- requires for checking membership
  let(:group) { create(:group_with_plan, plan: :ultimate_plan) } # rubocop:todo RSpec/FactoryBot/AvoidCreate -- requires for checking membership

  before do
    group.add_developer(user)
    allow(view).to receive(:resource).and_return(group)
    allow(view).to receive(:current_user).and_return(user)
  end

  subject(:rendered_alert) { view.content_for(:page_level_alert) }

  context 'when duo_chat_ga_alert feature flag is enabled' do
    it 'renders the duo pro trial alert' do
      render

      expect(rendered_alert).to have_text(s_('DuoChatGAAlert|GitLab Duo Chat is generally available today'))
      expect(rendered_alert).to have_text(s_('DuoChatGAAlert|Use GitLab Duo Chat'))
      expect(rendered_alert).to have_link(s_('DuoChatGAAlert|Access Chat in the IDE'),
        href: help_page_path('user/gitlab_duo_chat', anchor: 'use-gitlab-duo-chat-in-the-web-ide'))
    end
  end

  context 'when duo_chat_ga_alert feature flag is disabled' do
    before do
      stub_feature_flags(duo_chat_ga_alert: false)
    end

    it 'does not render the duo pro trial alert' do
      # Just `render` throws an exception in the case of early return in view
      # https://github.com/rails/rails/issues/41320
      view.render('shared/duo_chat_ga_alert')

      expect(rendered_alert).not_to have_text(s_('DuoChatGAAlert|GitLab Duo Chat is generally available today'))
    end
  end
end
