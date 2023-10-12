# frozen_string_literal: true

module Sbom
  class DependencyLicensesFinder
    MAXIMUM_LICENSES = 100

    def initialize(namespace:, params: {})
      @namespace = namespace
      @params = params
    end

    def execute
      # rubocop: disable CodeReuse/ActiveRecord
      namespace
        .sbom_occurrences(with_totals: false)
        .distinct(:licenses)
        .order(:licenses)
        .limit(MAXIMUM_LICENSES)
        .pluck(:licenses)
        .flatten
        .uniq { |license| license["spdx_identifier"] }
      # rubocop: enable CodeReuse/ActiveRecord
    end

    private

    attr_reader :namespace, :params
  end
end
