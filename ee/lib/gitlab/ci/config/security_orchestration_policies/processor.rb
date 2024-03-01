# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module SecurityOrchestrationPolicies
        class Processor
          DEFAULT_ON_DEMAND_STAGE = 'dast'
          DEFAULT_SECURITY_JOB_STAGE = 'test'

          DEFAULT_BUILD_STAGE = 'build'
          DEFAULT_SCAN_POLICY_STAGE = 'scan-policies'
          DEFAULT_POLICY_PRE_STAGE = '.pipeline-policy-pre'
          DEFAULT_POLICY_TEST_STAGE = '.pipeline-policy-test'
          DEFAULT_POLICY_POST_STAGE = '.pipeline-policy-post'
          DEFAULT_STAGES = Gitlab::Ci::Config::Entry::Stages.default

          def initialize(config, context, ref, source)
            @config = config.deep_dup
            @context = context
            @project = context.project
            @ref = ref
            @source = source
            @start = Time.current
          end

          def perform
            return @config unless project&.feature_available?(:security_orchestration_policies)
            return @config if valid_security_orchestration_policy_configurations.blank?
            return @config unless extend_configuration?

            @config[:workflow] = { rules: [{ when: 'always' }] } if @config.empty?

            merged_config = @config.deep_merge(merged_security_policy_config)

            if custom_scan_actions_enabled? && active_scan_custom_actions.any?
              merged_config = merged_config.deep_merge(scan_custom_actions[:pipeline_scan])

              merged_config[:stages] = insert_custom_scan_stages(merged_config[:stages])
            end

            merged_config[:stages] = cleanup_stages(merged_config[:stages])
            merged_config.delete(:stages) if merged_config[:stages].blank?

            observe_processing_duration(Time.current - @start)

            merged_config
          end

          private

          attr_reader :project, :ref, :context

          def custom_scan_actions_enabled?
            return false if project.group.nil?

            Feature.enabled?(
              :compliance_pipeline_in_policies,
              project
            ) && project.group.namespace_settings.toggle_security_policy_custom_ci?
          end

          def cleanup_stages(stages)
            stages.uniq!

            return if stages == DEFAULT_STAGES

            stages
          end

          def merged_security_policy_config
            @merged_security_policy_config ||= merge_policies_with_stages(@config)
          end

          def valid_security_orchestration_policy_configurations
            @valid_security_orchestration_policy_configurations ||=
              ::Gitlab::Security::Orchestration::ProjectPolicyConfigurations.new(@project).all
          end

          def prepare_on_demand_scans_template
            scan_templates[:on_demand]
          end

          def prepare_pipeline_scans_template
            scan_templates[:pipeline_scan]
          end

          def scan_templates
            @scan_templates ||= ::Security::SecurityOrchestrationPolicies::ScanPipelineService
              .new(context)
              .execute(active_scan_template_actions)
          end

          def scan_custom_actions
            @scan_custom_actions ||= ::Security::SecurityOrchestrationPolicies::ScanPipelineService
              .new(context, custom_ci_yaml_allowed: true)
              .execute(active_scan_custom_actions)
          end

          ## Add `dast` to the end of stages if `dast` is not in stages already
          ## For other scan types, add `scan-policies` stage after `build` stage if `test` stage is not defined
          def merge_policies_with_stages(config)
            merged_config = config
            defined_stages = config[:stages].presence || DEFAULT_STAGES.clone

            merge_on_demand_scan_template(merged_config, defined_stages)
            merge_pipeline_scan_template(merged_config, defined_stages)

            merged_config[:stages] = defined_stages + merged_config.fetch(:stages, [])

            merged_config
          end

          def merge_on_demand_scan_template(merged_config, defined_stages)
            on_demand_scan_template = prepare_on_demand_scans_template
            on_demand_scan_job_names = on_demand_scan_template.keys

            if on_demand_scan_template.present?
              insert_stage_before_or_append(defined_stages, DEFAULT_ON_DEMAND_STAGE, ['.post'])
              merged_config.except!(*on_demand_scan_job_names).deep_merge!(on_demand_scan_template)
            end
          end

          def merge_pipeline_scan_template(merged_config, defined_stages)
            pipeline_scan_template = prepare_pipeline_scans_template
            pipeline_scan_job_names = prepare_pipeline_scans_template.keys

            if pipeline_scan_template.present?
              unless defined_stages.include?(DEFAULT_SECURITY_JOB_STAGE)
                insert_stage_after_or_prepend(defined_stages, DEFAULT_SCAN_POLICY_STAGE, [DEFAULT_BUILD_STAGE])
                pipeline_scan_template = pipeline_scan_template.transform_values do |job_config|
                  job_config.merge(stage: DEFAULT_SCAN_POLICY_STAGE)
                end
              end

              merged_config.except!(*pipeline_scan_job_names).deep_merge!(pipeline_scan_template)
            end
          end

          def insert_custom_scan_stages(config_stages)
            config_stages.append(DEFAULT_POLICY_POST_STAGE)

            insert_stage_after_or_prepend(config_stages, DEFAULT_POLICY_TEST_STAGE, %w[test build .pre])

            config_stages.unshift(DEFAULT_POLICY_PRE_STAGE)
          end

          def insert_stage_after_or_prepend(stages, insert_stage_name, after_stages)
            after_stages.each do |stage|
              stage_index = stages.index(stage)

              next unless stage_index

              stages.insert(stage_index + 1, insert_stage_name)

              return stages
            end

            stages.unshift(insert_stage_name)
          end

          def insert_stage_before_or_append(stages, insert_stage_name, before_stages)
            before_stages.each do |stage|
              stage_index = stages.index(stage)

              next unless stage_index

              stages.insert(stage_index, insert_stage_name)

              return stages
            end

            stages << insert_stage_name
          end

          def active_scan_template_actions
            @active_scan_template_actions ||= active_scan_actions.reject { |action| action[:scan] == 'custom' }
          end

          def active_scan_custom_actions
            @active_scan_custom_actions ||= active_scan_actions.select { |action| action[:scan] == 'custom' }
          end

          def active_scan_actions
            scan_actions do |configuration|
              configuration.active_policies_scan_actions_for_project(ref, project)
            end
          end

          def scan_actions
            return [] if valid_security_orchestration_policy_configurations.blank?

            valid_security_orchestration_policy_configurations
              .flat_map do |security_orchestration_policy_configuration|
                yield(security_orchestration_policy_configuration)
              end.compact.uniq
          end

          def observe_processing_duration(duration)
            ::Gitlab::Ci::Pipeline::Metrics
              .pipeline_security_orchestration_policy_processing_duration_histogram
              .observe({}, duration.seconds)
          end

          def extend_configuration?
            return false if @source.nil?

            Enums::Ci::Pipeline.ci_sources.key?(@source.to_sym)
          end
        end
      end
    end
  end
end
