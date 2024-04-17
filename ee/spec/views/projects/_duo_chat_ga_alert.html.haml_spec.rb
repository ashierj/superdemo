# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_duo_chat_ga_alert', :saas, feature_category: :duo_chat do
  let(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate -- requires for checking member
  let(:group) { create(:group_with_plan, plan: :ultimate_plan) } # rubocop:todo RSpec/FactoryBot/AvoidCreate -- requires for checking member
  let(:project) { nil }

  before do
    group.add_developer(user)
    allow(view).to receive(:project).and_return(project)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'with personal project' do
    let(:project) { build(:project, namespace: user.namespace) }

    it 'does not render duo_chat_ga_alert template' do
      # Just `render` throws an exception in the case of early return in view
      # https://github.com/rails/rails/issues/41320
      view.render('projects/duo_chat_ga_alert')

      expect(rendered).not_to render_template('shared/_duo_chat_ga_alert')
    end
  end

  context 'with project within a group' do
    let(:project) { build(:project, namespace: group) }

    it 'renders duo_chat_ga_alert template' do
      render

      expect(rendered).to render_template('shared/_duo_chat_ga_alert')
    end
  end
end
