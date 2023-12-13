# frozen_string_literal: true

# EE:Self Managed
module Admin
  class CodeSuggestionsController < Admin::ApplicationController
    include ::GitlabSubscriptions::CodeSuggestionsHelper

    respond_to :html

    feature_category :seat_cost_management
    urgency :low

    before_action :ensure_feature_available!

    private

    def ensure_feature_available!
      render_404 unless gitlab_sm? && code_suggestions_available?
    end
  end
end
