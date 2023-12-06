# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_permissions.html.haml', :saas, feature_category: :code_suggestions do
  let_it_be(:group) { build(:group, namespace_settings: build(:namespace_settings)) }

  before do
    assign(:group, group)
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:current_user).and_return(build(:user))
  end

  context 'for code suggestions' do
    it 'renders nothing' do
      allow(view).to receive(:ai_assist_ui_enabled?).and_return(false)

      render

      expect(rendered).to render_template('groups/settings/_code_suggestions')
      expect(rendered).not_to have_content('What are code suggestions?')
    end

    it 'renders the ai assist settings' do
      allow(view).to receive(:ai_assist_ui_enabled?).and_return(true)

      render

      expect(rendered).to render_template('groups/settings/_code_suggestions')
      field_text = s_('CodeSuggestions|Projects in this group can use Code Suggestions')
      expect(rendered).to have_content(field_text)
      beta_link = help_page_path('user/project/repository/code_suggestions/index')
      expect(rendered).to have_link('What are code suggestions?', href: beta_link)
      test_link = 'https://about.gitlab.com/handbook/legal/testing-agreement/'
      expect(rendered).to have_link('Testing Terms of Use', href: test_link)
    end
  end

  context 'for experimental settings' do
    context 'when settings are disabled' do
      it 'renders nothing' do
        allow(view).to receive(:ai_assist_ui_enabled?).and_return(true)
        allow(group).to receive(:experiment_settings_allowed?).and_return(false)

        render

        expect(rendered).to render_template('groups/settings/_experimental_settings')
        expect(rendered).not_to have_content('Experiment and Beta features')
      end
    end

    context 'when experiment settings for group is enabled' do
      it 'renders the experiment settings' do
        allow(view).to receive(:ai_assist_ui_enabled?).and_return(true)
        allow(group).to receive(:experiment_settings_allowed?).and_return(true)

        render

        expect(rendered).to render_template('groups/settings/_experimental_settings')
        expect(rendered).to have_content('Experiment and Beta features')
      end
    end
  end

  context 'for product analytics settings' do
    before do
      allow(view).to receive(:ai_assist_ui_enabled?).and_return(true)
      allow(group).to receive(:licensed_feature_available?).and_call_original
      allow(group).to receive(:licensed_feature_available?).with(:experimental_features).and_return(true)
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
    end

    context 'as a sub-group' do
      it 'renders nothing' do
        allow(group).to receive(:root?).and_return(false)

        render

        expect(rendered).to render_template('groups/settings/_product_analytics_settings')
        expect(rendered).not_to have_content(_('Product Analytics'))
      end
    end

    context 'as a root group' do
      it 'renders the product analytics settings' do
        allow(group).to receive(:root?).and_return(true)

        render

        expect(rendered).to render_template('groups/settings/_product_analytics_settings')
        expect(rendered).to have_content(_('Product Analytics'))
      end
    end
  end
end
