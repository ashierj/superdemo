# frozen_string_literal: true

module Projects
  class MergeTrainsController < Projects::ApplicationController
    feature_category :merge_trains

    before_action :authorize_read_merge_train!
    before_action :check_enabled!

    def index; end

    private

    def check_enabled!
      render_404 unless Feature.enabled?(:merge_trains_viz, project)
    end
  end
end
