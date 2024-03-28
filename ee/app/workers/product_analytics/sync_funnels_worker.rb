# frozen_string_literal: true

module ProductAnalytics
  class SyncFunnelsWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :product_analytics_data_management
    idempotent!

    def perform(project_id, newrev, user_id)
      @project = Project.find_by_id(project_id)
      @commit = @project.repository.commit(newrev)
      @user_id = user_id
      @payload = build_payload

      return if @payload[:funnels].empty?

      response = Gitlab::HTTP.post(
        "#{ ::ProductAnalytics::Settings.for_project(@project)
                                       .product_analytics_configurator_connection_string }/funnel-schemas",
        body: build_payload.to_json,
        allow_local_requests: true
      )

      response.body
    end

    def build_payload
      {
        project_ids: ["gitlab_project_#{@project.id}"],
        funnels: funnels
      }
    end

    private

    def funnels
      [new_funnels, updated_funnels, deleted_funnels].flatten
    end

    def funnel_files
      @commit.deltas.select { |delta| delta.old_path.start_with?(".gitlab/analytics/funnels/") }
    end

    def new_funnels
      funnel_files.select(&:new_file).map do |file|
        funnel = ProductAnalytics::Funnel.from_diff(file, project: @project)
        {
          state: 'created',
          name: funnel.name,
          schema: funnel.to_json
        }
      end
    end

    def updated_funnels
      # if a file is not new, renamed, or deleted, but is in a diff, we assume it is changed.
      #
      funnel_files.select { |f| !f.new_file && !f.renamed_file && !f.deleted_file }.map do |file|
        funnel = ProductAnalytics::Funnel.from_diff(file, project: @project, commit: @commit)
        o = {
          state: 'updated',
          name: funnel.name,
          schema: funnel.to_json
        }

        o[:previous_name] = funnel.previous_name.parameterize(separator: '_') unless funnel.previous_name.nil?
        o
      end
    end

    def deleted_funnels
      funnel_files.select(&:deleted_file).map do |file|
        funnel = ProductAnalytics::Funnel.from_diff(file, project: @project, sha: @commit.parent.sha)
        {
          state: 'deleted',
          name: funnel.name
        }
      end
    end
  end
end
