# frozen_string_literal: true

class ElasticIndexInitialBulkCronWorker # rubocop:disable Scalability/IdempotentWorker
  include Elastic::BulkCronWorker

  feature_category :global_search
  urgency :low
  data_consistency :sticky

  private

  def service
    Elastic::ProcessInitialBookkeepingService.new
  end
end
