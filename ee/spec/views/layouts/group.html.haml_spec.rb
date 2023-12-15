# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/group', feature_category: :groups_and_projects do
  let(:user) { build_stubbed(:user) }
  let_it_be(:group) { create(:group) }

  before do
    assign(:group, group)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('shared/_free_user_cap_alert')
    end
  end

  context 'when code_suggestions_ga_non_owner_alert is present' do
    before do
      allow(view).to receive(:show_code_suggestions_ga_non_owner_alert?).and_return(true)
    end

    it 'renders supported IDE extensions doc link' do
      render

      expect(rendered).to have_link('your IDE',
        href: help_page_path('user/project/repository/code_suggestions/index', anchor: 'supported-editor-extensions'))
    end

    context 'with code_suggestions_ga_non_owner_alert_end_date feature flag' do
      it 'renders the end date sentence when the flag is enabled' do
        render

        expect(rendered).to have_content(_('Code Suggestions transitions to a paid feature on February 15, 2024'))
      end

      it 'renders the end date sentence when the flag is disabled' do
        stub_feature_flags(code_suggestions_ga_non_owner_alert_end_date: false)

        render

        expect(rendered).not_to have_content(_('Code Suggestions transitions to a paid feature on February 15, 2024'))
      end
    end
  end
end
