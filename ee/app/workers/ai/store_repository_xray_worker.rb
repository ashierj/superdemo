# frozen_string_literal: true

module Ai
  class StoreRepositoryXrayWorker
    include ApplicationWorker

    data_consistency :sticky

    idempotent!

    sidekiq_options retry: true

    feature_category :code_suggestions

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        break unless pipeline.has_repository_xray_reports?

        Ai::StoreRepositoryXrayService.execute(pipeline)
      end
    end
  end
end
