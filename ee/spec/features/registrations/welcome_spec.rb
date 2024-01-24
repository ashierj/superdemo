# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen on SaaS', :js, :saas, feature_category: :onboarding do
  context 'with email opt in' do
    let(:user) { create(:user, role: nil) }
    let(:opt_in_selector) { 'input[name="user[onboarding_status_email_opt_in]"]' }

    before do
      gitlab_sign_in(user)

      visit users_sign_up_welcome_path
    end

    it 'does not show the email opt in checkbox when setting up for a company' do
      expect(page).to have_content('We won\'t share this information with anyone')
      expect(page).not_to have_selector(opt_in_selector, visible: :visible)

      choose 'user_setup_for_company_true'

      expect(page).not_to have_selector(opt_in_selector, visible: :visible)
    end

    it 'shows the email opt in checkbox when setting up for just me' do
      expect(page).to have_content('We won\'t share this information with anyone')
      expect(page).not_to have_selector(opt_in_selector, visible: :visible)

      choose 'user_setup_for_company_false'

      expect(page).to have_selector(opt_in_selector, visible: :visible)
    end
  end
end
