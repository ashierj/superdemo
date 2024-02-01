# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Google Artifact Registry', :js, feature_category: :container_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before_all do
    project.add_developer(user)
  end

  before do
    stub_container_registry_config(enabled: true)
    stub_saas_features(google_artifact_registry: true)
    sign_in(user)
  end

  it 'passes axe automated accessibility testing' do
    visit_page

    wait_for_requests

    # rubocop:disable Capybara/TestidFinders -- Helper within_testid doesn't cover use case
    expect(page).to be_axe_clean.within('[data-testid="artifact-registry-list-page"]')
    # rubocop:enable Capybara/TestidFinders
  end

  it 'has a page title set' do
    visit_page

    expect(page).to have_title _('Google Artifact Registry')
  end

  it 'has external link to google cloud' do
    visit_page

    expect(page).to have_link _('Open in Google Cloud')
  end

  describe 'link to settings' do
    context 'when user is not a group owner' do
      it 'does not show group settings link' do
        visit_page

        expect(page).not_to have_link('Configure in settings',
          href: edit_project_settings_integration_path(project, ::Integrations::GoogleCloudPlatform::ArtifactRegistry))
      end
    end

    context 'when user is a group maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      it 'shows group settings link' do
        visit_page

        expect(page).to have_link('Configure in settings',
          href: edit_project_settings_integration_path(project, ::Integrations::GoogleCloudPlatform::ArtifactRegistry))
      end
    end
  end

  describe 'details page' do
    it 'has a page title set' do
      visit project_google_cloud_platform_artifact_registry_image_path(project, {
        image: 'alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
        project: 'dev-package-container-96a3ff34',
        repository: 'myrepo',
        location: 'us-east1'
      })

      expect(page).to have_text _('alpine@6a0657acfef7')
    end
  end

  private

  def visit_page
    visit project_google_cloud_platform_artifact_registry_index_path(project)
  end
end
