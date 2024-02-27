# frozen_string_literal: true

module EE
  module Event
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      scope :issues, -> { where(target_type: 'Issue') }
      scope :merge_requests, -> { where(target_type: 'MergeRequest') }
      scope :totals_by_author, -> { group(:author_id).count }
      scope :totals_by_author_target_type_action, -> { group(:author_id, :target_type, :action).count }
      scope :epics, -> { where(target_type: 'Epic') }
      scope :for_projects_after, ->(projects, date) { where(project: projects, created_at: date..) }

      scope :epic_contributions, -> do
        target_contribution_actions = [actions[:created], actions[:closed], actions[:merged], actions[:approved]]

        where("target_type IN ('Epic') AND action IN (?)", target_contribution_actions)
      end
    end

    EPIC_ACTIONS = [:created, :closed, :reopened].freeze
    EE_CONTRIBUTABLE_TARGET_TYPES = %w[Epic].freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      override :contributable_target_types
      def contributable_target_types
        return super unless ::Feature.enabled?(:epic_events_on_contributions_calendar)

        super + EE_CONTRIBUTABLE_TARGET_TYPES
      end
    end

    override :capabilities
    def capabilities
      super.merge(
        read_epic: %i[epic? epic_note?],
        read_security_resource: %i[vulnerability?]
      )
    end

    def epic_note?
      note? && note_target.is_a?(::Epic)
    end

    def epic?
      target_type == 'Epic'
    end

    def vulnerability_note?
      note? && note_target.is_a?(::Vulnerability)
    end

    def vulnerability?
      target_type == 'Vulnerability'
    end
  end
end
