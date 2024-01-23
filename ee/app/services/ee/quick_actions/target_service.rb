# frozen_string_literal: true

module EE
  module QuickActions
    module TargetService
      def execute(type, type_iid)
        return epic(type_iid) if type&.casecmp('epic') == 0

        super
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def epic(type_iid)
        # Some services still pass a group to this service as a param
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/435902
        epic_group = group || params[:group]
        return epic_group.epics.build if type_iid.nil?

        EpicsFinder.new(current_user, group_id: epic_group.id).find_by(iid: type_iid) || epic_group.epics.build
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
