# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'subscriptions/trials/duo_pro/_select_namespace_form.html.haml', feature_category: :purchase do
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }

  before do
    allow(view).to receive(:current_user) { user }
    allow(view).to receive(:duo_pro_trial_eligible_namespaces).and_return([group])
  end

  it 'renders select namespace form' do
    render 'subscriptions/trials/duo_pro/select_namespace_form'

    expect(rendered).to have_content(s_('DuoProTrial|Apply your GitLab Duo Pro trial to an existing group'))
    expect(rendered).to have_content(_('Who will be using GitLab?'))
    expect(rendered).to have_content(_('My company or team'))
    expect(rendered).to have_content(_('Just me'))

    expect(rendered).to render_template('subscriptions/trials/duo_pro/_advantages_list')
  end
end
