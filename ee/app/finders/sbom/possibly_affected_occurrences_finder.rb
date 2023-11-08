# frozen_string_literal: true

module Sbom
  class PossiblyAffectedOccurrencesFinder
    include Gitlab::Utils::StrongMemoize

    BATCH_SIZE = 100

    # Initializes the finder.
    #
    # @param purl_type [string] PURL type of the component to search for
    # @param package_name [string] Package name of the component to search for
    # @param global [boolean] When true, search in all projects including those
    #                         where Continuous Vulnerability Scanning isn't enabled.
    def initialize(purl_type:, package_name:, global:)
      @purl_type = purl_type
      @package_name = package_name
      @global = global
    end

    def execute_in_batches(of: BATCH_SIZE)
      return unless component_id

      Sbom::Occurrence.filter_by_components(component_id).each_batch(of: of) do |batch|
        components = batch
          .with_component_source_version_project_and_pipeline
          .filter_by_non_nil_component_version

        if global
          yield components
        else
          yield components.filter_by_cvs_enabled
        end
      end
    end

    private

    attr_reader :package_name, :purl_type, :global

    def component_id
      Sbom::Component
        .libraries
        .by_purl_type_and_name(purl_type, package_name)
        .select(:id)
        .first
    end
    strong_memoize_attr :component_id
  end
end
