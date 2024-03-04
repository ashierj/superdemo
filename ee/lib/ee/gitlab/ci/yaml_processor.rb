# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module YamlProcessor
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize

        override :validate_job!
        def validate_job!(name, job)
          super

          validate_job_identity!(name, job)
        end

        private

        def validate_job_identity!(name, job)
          return if job[:identity].blank?

          unless google_cloud_support_saas_feature?
            error!("#{name} job: #{s_('GoogleCloudPlatformService|The google_cloud_support feature is not available')}")
          end

          unless google_cloud_support_feature_flag?
            error!("#{name} job: google_cloud_support_feature_flag feature flag is not enabled for the " \
                   'top-level namespace')
          end

          integration = project.google_cloud_platform_workload_identity_federation_integration
          if integration.nil?
            error!("#{name} job: #{s_('GoogleCloudPlatformService|The Google Cloud Identity and Access Management ' \
                                      'integration is not configured for this project')}")
          end

          return if integration.active?

          error!("#{name} job: #{s_('GoogleCloudPlatformService|The Google Cloud Identity and Access Management ' \
                                    'integration is not enabled for this project')}")
        end

        def google_cloud_support_saas_feature?
          ::Gitlab::Saas.feature_available?(:google_cloud_support)
        end
        strong_memoize_attr :google_cloud_support_saas_feature?

        def google_cloud_support_feature_flag?
          ::Feature.enabled?(:google_cloud_support_feature_flag, project.root_ancestor)
        end
        strong_memoize_attr :google_cloud_support_feature_flag?
      end
    end
  end
end
