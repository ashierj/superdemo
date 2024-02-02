# frozen_string_literal: true

module Projects
  class LogsController < Projects::ApplicationController
    include ::Observability::ContentSecurityPolicy

    feature_category :metrics

    before_action :authorize_read_observability_logs!

    def index; end
  end
end
