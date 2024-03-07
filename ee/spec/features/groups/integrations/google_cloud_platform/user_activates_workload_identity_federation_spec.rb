# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Workload Identity Federation', feature_category: :integrations do
  include_context 'group integration activation'

  let(:integration) { build_stubbed(:google_cloud_platform_workload_identity_federation_integration) }

  before do
    stub_saas_features(google_cloud_support: true)
  end

  it 'activates integration', :js do
    visit_group_integration(integration.title)
    click_on s_('GoogleCloudPlatformService|Manual setup')

    fill_in(
      s_('GoogleCloudPlatformService|Project ID'),
      with: integration.workload_identity_federation_project_id)
    fill_in(
      s_('GoogleCloudPlatformService|Project number'),
      with: integration.workload_identity_federation_project_number)
    fill_in(
      s_('GoogleCloudPlatformService|Pool ID'),
      with: integration.workload_identity_pool_id)
    fill_in(
      s_('GoogleCloudPlatformService|Provider ID'),
      with: integration.workload_identity_pool_provider_id)

    click_save_integration

    expect(page).to have_content("#{integration.title} settings saved and active.")
  end
end
