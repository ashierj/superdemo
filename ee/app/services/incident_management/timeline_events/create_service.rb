# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    DEFAULT_ACTION = 'comment'

    class CreateService < TimelineEvents::BaseService
      def initialize(incident, user, params)
        @project = incident.project
        @incident = incident
        @user = user
        @params = params
      end

      def execute
        return error_no_permissions unless allowed?

        timeline_event_params = {
          project: project,
          incident: incident,
          author: user,
          note: params[:note],
          action: params.fetch(:action, DEFAULT_ACTION),
          note_html: params[:note_html].presence || params[:note],
          occurred_at: params[:occurred_at]
        }

        timeline_event = IncidentManagement::TimelineEvent.new(timeline_event_params)

        if timeline_event.save
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :project, :user, :incident, :params
    end
  end
end
