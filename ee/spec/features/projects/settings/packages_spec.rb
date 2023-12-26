# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Packages and registries > Dependency proxy for Packages',
  feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  subject(:visit_page) { visit project_settings_packages_and_registries_path(project) }

  before do
    stub_licensed_features(dependency_proxy_for_packages: true)
    stub_config(dependency_proxy: { enabled: true })

    sign_in(user)
  end

  context 'as owner', :js do
    it 'passes axe automated accessibility testing' do
      visit_page

      wait_for_requests

      # rubocop:disable Capybara/TestidFinders -- Helper within_testid doesn't cover use case
      expect(page).to be_axe_clean.within('[data-testid="packages-and-registries-project-settings"]')
                                  .skipping :'heading-order'
      # rubocop:enable Capybara/TestidFinders
    end
  end
end
