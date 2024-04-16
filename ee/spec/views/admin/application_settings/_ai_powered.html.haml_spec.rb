# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_ai_powered', :with_cloud_connector, feature_category: :ai_abstraction_layer do
  let_it_be(:application_setting) { build(:application_setting) }

  before do
    stub_licensed_features(ai_chat: true)
    assign(:application_setting, application_setting)
  end

  it 'renders the settings app root' do
    render

    expect(rendered).to have_selector('#js-ai-powered-settings')
  end
end
