# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor' do
    describe(
      'Product Analytics',
      :requires_admin,
      only: { pipeline: %i[staging staging-canary] },
      product_group: :product_analytics
    ) do
      let!(:sandbox_group) { create(:sandbox, path: "gitlab-qa-product-analytics") }
      let!(:group) { create(:group, name: "product-analytics-g-#{SecureRandom.hex(8)}", sandbox: sandbox_group) }

      let!(:project) do
        create(:project, :with_readme, name: "project-analytics-p-#{SecureRandom.hex(8)}", group: group)
      end

      before do
        Flow::Login.sign_in_as_admin

        Flow::Group.update_to_ultimate(sandbox_group)
        Flow::Group.enable_product_analytics(sandbox_group)
      end

      it 'can be onboarded', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/432598' do
        sdk_host = 0
        sdk_app_id = 0

        project.visit!
        Page::Project::Menu.perform(&:go_to_analytics_dashboards)
        EE::Page::Project::Analyze::AnalyticsDashboards::Initial.perform(&:click_set_up)
        EE::Page::Project::Analyze::AnalyticsDashboards::Setup.perform(&:click_set_up_product_analytics)

        EE::Page::Project::Analyze::AnalyticsDashboards::Setup.perform do |analytics_dashboards_setup|
          analytics_dashboards_setup.wait_for_sdk_containers
          sdk_host = analytics_dashboards_setup.sdk_host.value
          sdk_app_id = analytics_dashboards_setup.sdk_application_id.value
        end

        Vendor::Snowplow::ProductAnalytics::Event.perform do |event|
          payload = event.build_payload(sdk_app_id)
          event.send(sdk_host, payload)
        end

        EE::Page::Project::Analyze::AnalyticsDashboards::Home.perform do |analytics_dashboards|
          analytics_dashboards.wait_for_dashboards_list
          analytics_dashboards.open_audience_dashboard
        end

        EE::Page::Project::Analyze::AnalyticsDashboards::Dashboard.perform do |dashboard|
          panels = dashboard.audience_dashboard_panels
          aggregate_failures 'test audience dashboard' do
            expect(panels.count).to equal(9)
            expect(panels[2]).to have_content('Total Unique Users')
            expect(panels[2]).to have_content("1")
          end
        end

        Page::Project::Menu.perform(&:go_to_analytics_dashboards)

        EE::Page::Project::Analyze::AnalyticsDashboards::Home.perform(&:open_behavior_dashboard)

        EE::Page::Project::Analyze::AnalyticsDashboards::Dashboard.perform do |dashboard|
          panels = dashboard.behavior_dashboard_panels
          aggregate_failures 'test audience dashboard' do
            expect(panels.count).to equal(5)
            expect(panels[2]).to have_content('Total events')
            expect(panels[2]).to have_content("1")
          end
        end
      end
    end
  end
end
