# frozen_string_literal: true

module Groups
  class DiscoversController < Groups::ApplicationController
    before_action :authorize_admin_group!
    before_action :authorize_discover_page
    before_action :verify_namespace_plan_check_enabled

    layout 'group'

    feature_category :activation
    urgency :low

    def show; end

    private

    def authorize_discover_page
      return render_404 if experiment(:trial_discover_page, actor: current_user).assigned[:name] == :control

      render_404 unless group.trial_active?
    end
  end
end
