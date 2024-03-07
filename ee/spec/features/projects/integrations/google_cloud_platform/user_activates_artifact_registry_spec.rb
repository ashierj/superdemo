# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Artifact Registry', :js, :sidekiq_inline, feature_category: :container_registry do
  include_context 'project integration activation'

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, projects: [project], parent: parent_group) }
  let(:integration) { build_stubbed(:google_cloud_platform_artifact_registry_integration) }

  before_all do
    parent_group.add_owner(user)
  end

  before do
    stub_saas_features(google_cloud_support: true)
  end

  subject(:visit_page) { visit_project_integration('Google Artifact Registry') }

  shared_examples 'activates integration' do
    it 'activates integration' do
      visit_page

      expect(page).not_to have_link('View artifacts')

      fill_in s_('GoogleCloudPlatformService|Google Cloud project ID'),
        with: integration.artifact_registry_project_id
      fill_in s_('GoogleCloudPlatformService|Repository location'),
        with: integration.artifact_registry_location
      fill_in s_('GoogleCloudPlatformService|Repository name'),
        with: integration.artifact_registry_repositories

      click_save_integration

      expect(page).to have_content('Google Artifact Registry settings saved and active.')

      expect(page).to have_link('View artifacts',
        href: project_google_cloud_artifact_registry_index_path(project))
    end
  end

  shared_examples 'inactive integration' do
    it 'shows empty state & links to iam integration page' do
      visit_page

      expect(page).to have_link('Set up Google Cloud IAM',
        href: edit_project_settings_integration_path(project, :google_cloud_platform_workload_identity_federation))
      expect(page).to have_button('Invite member to set up')
    end
  end

  context 'when the iam integration is not active' do
    it_behaves_like 'inactive integration'
  end

  context 'with an active iam integration in the root group' do
    let_it_be(:root_group_integration) do
      create(:google_cloud_platform_workload_identity_federation_integration, project: nil, group: parent_group)
    end

    before do
      ::Integrations::PropagateService.new(root_group_integration).execute
    end

    it_behaves_like 'activates integration'

    context 'and inactive at project level' do
      before do
        project.google_cloud_platform_workload_identity_federation_integration.update_column(:active, false)
      end

      it_behaves_like 'inactive integration'
    end
  end
end
