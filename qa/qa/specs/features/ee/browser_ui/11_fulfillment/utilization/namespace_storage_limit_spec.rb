# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin,
    only: { subdomain: :staging },
    feature_flag: { name: 'namespace_storage_limit', scope: :group },
    product_group: :utilization do
    describe 'Utilization' do
      include Runtime::Fixtures

      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:group) do
        Resource::Sandbox.init do |resource|
          resource.api_client = admin_api_client
          resource.path = "quality-e2e-tests"
        end.reload!
      end

      let(:project) do
        create(:project,
          name: "project-#{SecureRandom.hex(8)}",
          group: group
        )
      end

      let!(:runner) do
        create(:project_runner,
          name: executor,
          tags: [executor],
          project: project)
      end

      let(:one_b_file_path) do
        File.expand_path('../../../../../../fixtures/files/one_b', __dir__)
      end

      let(:one_b_file_content) do
        File.read(one_b_file_path).to_s
      end

      let(:application_settings_endpoint) do
        QA::Runtime::API::Request.new(admin_api_client, '/application/settings').url
      end

      let(:plan_limits_endpoint) do
        QA::Runtime::API::Request.new(admin_api_client, '/application/plan_limits').url
      end

      let(:storage_warning_message) do
        "If #{group.name} exceeds the storage quota, your ability to write new data to this namespace will be " \
          "restricted."
      end

      let(:storage_limit_reached_message) do
        "#{group.name} is now read-only. Your ability to write new data to this namespace is restricted."
      end

      before do
        Flow::Login.sign_in

        Runtime::Feature.enable(:namespace_storage_limit, group: group)
        Runtime::Feature.enable(:namespace_storage_limit_show_preenforcement_banner, group: group)
        Runtime::Feature.enable(:reduce_aggregation_schedule_lease, group: group)

        put application_settings_endpoint, { namespace_aggregation_schedule_lease_duration_in_seconds: 1 }
        put plan_limits_endpoint, {
          plan_name: 'free',
          notification_limit: 9216,
          enforcement_limit: 10240,
          storage_limit: 10240
        }

        group.visit!
      end

      after do
        put application_settings_endpoint, { namespace_aggregation_schedule_lease_duration_in_seconds: 300 }
        put plan_limits_endpoint, {
          plan_name: 'free',
          notification_limit: 5120,
          enforcement_limit: 5120,
          storage_limit: 5120
        }

        runner.remove_via_api!
      end

      context 'when namespace storage usage hits the limit' do
        it(
          'puts the project into read-only mode',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/437114'
        ) do
          expect_storage_limit_message(storage_warning_message, 'Warning for storage limit not shown')

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.file_name = 'one_b'
            push.file_content = one_b_file_content
            push.commit_message = 'Commit 1B of data'
          end

          expect_storage_limit_message(storage_limit_reached_message, 'Alert for storage limit exceeded not shown')
        end
      end

      def expect_storage_limit_message(message, error_message)
        Page::Alert::StorageLimit.perform do |storage_limit_alert|
          Support::Retrier.retry_until(
            max_duration: 300,
            sleep_interval: 10,
            retry_on_exception: true,
            message: error_message) do
            page.refresh
            expect(storage_limit_alert.storage_limit_message).to have_content(message)
          end
        end
      end
    end
  end
end
