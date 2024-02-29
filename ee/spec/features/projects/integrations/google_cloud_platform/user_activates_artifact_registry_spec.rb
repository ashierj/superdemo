# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Artifact Registry', feature_category: :package_registry do
  include_context 'project integration activation'

  let(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration) }

  before do
    stub_saas_features(google_cloud_support: true)
  end

  it 'activates integration', :js do
    visit_project_integration('Google Artifact Registry')

    expect(page).not_to have_link('View artifacts')

    fill_in s_('GoogleCloudPlatformService|Google Cloud project ID'),
      with: integration.artifact_registry_project_id
    fill_in s_('GoogleCloudPlatformService|Repository location'),
      with: integration.artifact_registry_location
    fill_in s_('GoogleCloudPlatformService|Repository name'),
      with: integration.artifact_registry_repositories

    click_save_integration

    expect(page).to have_content('Google Artifact Registry settings saved and active.')

    expect(page).to have_link('View artifacts')
  end
end
