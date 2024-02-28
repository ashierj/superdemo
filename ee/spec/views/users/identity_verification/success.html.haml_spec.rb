# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'users/identity_verification/success.html.haml', feature_category: :onboarding do
  context 'when tracking_label is set' do
    before do
      assign(:tracking_label, '_tracking_label_')
    end

    it 'assigns the tracking items' do
      render

      expect(rendered).to have_css("[data-track-action='render'][data-track-label='_tracking_label_']")
    end
  end

  context 'when tracking_label is not set' do
    it 'assigns the tracking items' do
      render

      expect(rendered).not_to have_css("[data-track-action='render'][data-track-label='_tracking_label_']")
    end
  end
end
