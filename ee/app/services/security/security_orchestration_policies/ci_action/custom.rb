# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    module CiAction
      class Custom < Base
        def config
          if @action[:ci_configuration]
            custom_pipeline_configuration
          elsif @action[:ci_configuration_path]
            Gitlab::Ci::Config::External::Processor.new(
              { include: action[:ci_configuration_path] }, @context
            ).perform
          end
        end

        private

        def custom_pipeline_configuration
          Gitlab::Ci::Config.new(@action[:ci_configuration], inject_edge_stages: false, user: @context.user).to_hash
        rescue Gitlab::Ci::Config::ConfigError => e
          {
            generate_job_name_with_index('security_policy_ci') => {
              'script' => "echo \"Error parsing security policy CI configuration: #{e.message}\" && false",
              'allow_failure' => true
            }
          }
        end
      end
    end
  end
end
