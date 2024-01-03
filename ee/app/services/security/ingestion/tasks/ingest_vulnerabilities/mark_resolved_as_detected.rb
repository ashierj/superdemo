# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestVulnerabilities
        class MarkResolvedAsDetected < AbstractTask
          include Gitlab::Utils::StrongMemoize

          def execute
            mark_as_resolved

            finding_maps
          end

          private

          # rubocop:disable CodeReuse/ActiveRecord
          def mark_as_resolved
            ApplicationRecord.transaction do
              create_state_transitions
              update_vulnerability_records
            end

            set_transitioned_to_detected
          end

          def redetected_vulnerability_ids
            strong_memoize(:redetected_vulnerability_ids) do
              ::Vulnerability.resolved.where(id: finding_maps.map(&:vulnerability_id)).pluck(:id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- `finding_maps` collection can have max 100 objects
            end
          end

          def update_vulnerability_records
            ::Vulnerability.resolved
                           .where(id: redetected_vulnerability_ids)
                           .update_all(state: :detected)
          end
          # rubocop:enable CodeReuse/ActiveRecord

          def create_state_transitions
            redetected_vulnerability_ids.each do |vulnerability_id|
              create_state_transition_for(vulnerability_id)
            end
          end

          def create_state_transition_for(vulnerability_id)
            ::Vulnerabilities::StateTransition.create!(
              vulnerability_id: vulnerability_id,
              from_state: :resolved,
              to_state: :detected
            )
          end

          def set_transitioned_to_detected
            updated_finding_maps.each { |finding_map| finding_map.transitioned_to_detected = true }
          end

          def updated_finding_maps
            finding_maps.select { |finding_map| redetected_vulnerability_ids.include?(finding_map.vulnerability_id) }
          end
        end
      end
    end
  end
end
