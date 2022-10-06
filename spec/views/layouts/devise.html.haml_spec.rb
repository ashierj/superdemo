# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/devise' do
  it_behaves_like 'a layout which reflects the application theme setting'

  describe 'logo' do
    it 'renders GitLab logo' do
      render

      expect(rendered).to have_selector('img[alt^="GitLab"]')
    end

    context 'with custom logo' do
      let_it_be(:appearance) { create(:appearance, logo: fixture_file_upload('spec/fixtures/dk.png')) }

      it 'renders custom logo' do
        render

        expect(rendered).to have_selector('img[data-src$="dk.png"]')
      end
    end
  end
end
