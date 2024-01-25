# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'subscriptions/trials/duo_pro/_select_namespace_form.html.haml', feature_category: :purchase do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:current_user) { user }
  end

  it 'renders select namespace form' do
    render 'subscriptions/trials/duo_pro/select_namespace_form'

    expect(rendered).to have_content(s_('DuoProTrial|Create a group to start your Duo Pro trial'))
    expect(rendered).to have_content(_('Who will be using GitLab?'))
    expect(rendered).to have_content(_('My company or team'))
    expect(rendered).to have_content(_('Just me'))

    expect(rendered).to render_template('subscriptions/trials/duo_pro/_advantages_list')
  end

  context 'when there is trial eligible namespace' do
    let_it_be(:group) { build_stubbed(:group) }

    before do
      allow(user).to receive(:manageable_namespaces_eligible_for_trial).and_return([group])
    end

    it 'renders correct title' do
      render 'subscriptions/trials/duo_pro/select_namespace_form'

      expect(rendered).to have_content(s_('DuoProTrial|Apply your Duo Pro trial to a new or existing group'))
    end
  end
end
