# frozen_string_literal: true

module Projects
  class ParticipantsService < BaseService
    include Users::ParticipableService

    def execute(noteable)
      @noteable = noteable

      participants =
        noteable_owner +
        participants_in_noteable +
        all_members +
        project_members +
        groups

      render_participants_as_hash(participants.uniq)
    end

    def project_members
      relation = project.authorized_users

      if params[:search]
        relation.gfm_autocomplete_search(params[:search]).limit(SEARCH_LIMIT).tap do |users|
          preload_status(users)
        end
      else
        sorted(relation)
      end
    end

    def all_members
      return [] if Feature.enabled?(:disable_all_mention)

      [{ username: "all", name: "All Project and Group Members", count: project.authorized_users.count }]
    end
  end
end
