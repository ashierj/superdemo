# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Job
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            EE_ALLOWED_KEYS = %i[dast_configuration identity secrets].freeze

            prepended do
              attributes :dast_configuration, :secrets

              entry :dast_configuration, ::Gitlab::Ci::Config::Entry::DastConfiguration,
                description: 'DAST configuration for this job',
                inherit: false

              entry :identity, ::Gitlab::Ci::Config::Entry::Identity,
                description: 'Configured workload identity for this job.',
                inherit: false

              entry :secrets, ::Gitlab::Config::Entry::ComposableHash,
                description: 'Configured secrets for this job',
                inherit: false,
                metadata: { composable_class: ::Gitlab::Ci::Config::Entry::Secret }
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :allowed_keys
              def allowed_keys
                super + EE_ALLOWED_KEYS
              end
            end

            override :value
            def value
              super.merge({
                dast_configuration: dast_configuration_value,
                identity: identity_available? ? identity_value : nil,
                secrets: secrets_value
              }.compact)
            end

            private

            def identity_available?
              ::Gitlab::Ci::YamlProcessor::FeatureFlags.enabled?(:ci_yaml_support_for_identity_provider, type: :beta) &&
                ::Gitlab::Saas.feature_available?(:google_cloud_support)
            end
          end
        end
      end
    end
  end
end
