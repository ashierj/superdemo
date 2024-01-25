# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'subscriptions/trials/duo_pro/_advantages_list.html.haml', feature_category: :purchase do
  it 'renders the list' do
    render 'subscriptions/trials/duo_pro/advantages_list'

    expect(rendered).to have_content(s_('DuoProTrial|Accelerate coding'))
    expect(rendered).to have_content(s_('DuoProTrial|Keep your Source Code protected'))
    expect(rendered).to have_content(s_('DuoProTrial|Billions of lines of code at your fingertips'))
    expect(rendered).to have_content(s_('DuoProTrial|Support in your language of choice'))
  end
end
