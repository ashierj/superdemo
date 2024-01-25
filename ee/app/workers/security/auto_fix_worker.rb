# frozen_string_literal: true

module Security
  class AutoFixWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :software_composition_analysis

    idempotent!

    def perform(pipeline_id); end
  end
end
