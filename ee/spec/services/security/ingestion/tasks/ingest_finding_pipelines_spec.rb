# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestFindingPipelines, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:pipelines) { build_stubbed_list(:ci_pipeline, 2) }
    let(:service_object) { described_class.new(nil, finding_maps) }

    let_it_be(:finding_maps) do
      pipelines.map { |pipeline| create(:finding_map, :with_finding, pipeline: pipeline) }
    end

    def finding_pipelines
      Vulnerabilities::Finding.id_in(finding_maps.map(&:finding_id)).map do |finding|
        {
          finding_id: finding.id,
          pipeline_ids: finding.finding_pipelines.pluck(:pipeline_id)
        }
      end
    end

    subject(:ingest_finding_pipelines) { service_object.execute }

    it 'associates the findings with pipeline from finding_map' do
      expect(finding_pipelines).to match_array(
        finding_maps.map { |finding_map| { finding_id: finding_map.finding_id, pipeline_ids: [] } }
      )

      ingest_finding_pipelines

      expect(finding_pipelines).to match_array(
        finding_maps.map { |finding_map| { finding_id: finding_map.finding_id, pipeline_ids: [finding_map.pipeline.id] } }
      )
    end

    it_behaves_like 'bulk insertable task'
  end
end
