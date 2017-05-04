require 'rails_helper'

feature 'Internal Snippets', feature: true do
  let(:internal_snippet) { create(:personal_snippet, :internal) }

  describe 'normal user' do
    before do
      login_as :user
    end

    scenario 'sees internal snippets' do
      visit snippet_path(internal_snippet)

      expect(page).to have_content(internal_snippet.content)
    end

    scenario 'sees raw internal snippets' do
      visit raw_snippet_path(internal_snippet)

      expect(page).to have_content(internal_snippet.content)
    end
  end
end
