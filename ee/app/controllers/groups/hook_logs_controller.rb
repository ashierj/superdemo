# frozen_string_literal: true

module Groups
  class HookLogsController < Groups::ApplicationController
    include ::Integrations::HooksExecution

    before_action :authorize_admin_group!

    before_action :hook, only: [:show, :retry]
    before_action :hook_log, only: [:show, :retry]

    respond_to :html

    layout 'group_settings'

    feature_category :integrations
    urgency :low, [:retry]

    def show
    end

    def retry
      execute_hook
      redirect_to edit_group_hook_path(@group, @hook)
    end

    private

    def execute_hook
      result = hook.execute(hook_log.request_data, hook_log.trigger)
      set_hook_execution_notice(result)
    end

    def hook
      @hook ||= @group.hooks.find(params[:hook_id])
    end

    def hook_log
      @hook_log ||= hook.web_hook_logs.find(params[:id])
    end
  end
end
