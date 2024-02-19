# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Artifact Registry', feature_category: :package_registry do
  include_context 'project integration activation'

  let(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration) }

  before do
    stub_saas_features(google_cloud_support: true)
  end

  it 'activates integration', :js do
    visit_project_integration('Google Cloud Artifact Registry')

    expect(page).not_to have_link('View artifacts')

    fill_in s_('GoogleCloudPlatformService|Workload Identity Pool project number'),
      with: integration.workload_identity_pool_project_number
    fill_in s_('GoogleCloudPlatformService|Workload Identity Pool ID'),
      with: integration.workload_identity_pool_id
    fill_in s_('GoogleCloudPlatformService|Workload Identity Pool provider ID'),
      with: integration.workload_identity_pool_provider_id
    fill_in s_('GoogleCloudPlatformService|Google Cloud project ID'),
      with: integration.artifact_registry_project_id
    fill_in s_('GoogleCloudPlatformService|Location of Artifact Registry repository'),
      with: integration.artifact_registry_location
    fill_in s_('GoogleCloudPlatformService|Repository of Artifact Registry'),
      with: integration.artifact_registry_repositories

    click_save_integration

    expect(page).to have_content('Google Cloud Artifact Registry settings saved and active.')

    expect(page).to have_link('View artifacts')
  end
end
