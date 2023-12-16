# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::StoreRepositoryXrayService, feature_category: :code_suggestions do
  let_it_be(:project) { create(:project) }

  subject(:execute) { described_class.new(pipeline).execute }

  context 'with xray report' do
    let(:pipeline) do
      create(:ee_ci_pipeline, :with_repository_xray_report, ref: 'master', project: project, user: project.creator)
    end

    it 'will store a Projects::XrayReport' do
      expect(Projects::XrayReport).to receive(:upsert)
        .with(hash_including({ project_id: project.id, lang: 'go' }), unique_by: [:project_id, :lang])

      execute
    end

    context 'if report is invalid' do
      it 'will log an error' do
        expect_next_instance_of(Gitlab::Ci::Build::Artifacts::Adapters::GzipStream) do |stream|
          expect(stream).to receive(:each_blob).and_yield("{ invalid: -------", "ruby.json")
        end

        expect(described_class).to receive(:log_event).with(
          hash_including({ action: 'xray_report_parse',
                           error: 'Parsing failed unexpected character (after ) at ' \
                                  'line 1, column 3 [parse.c:804] in \'{ invalid: -------' }))

        execute
      end
    end
  end

  context 'without xray report' do
    let(:pipeline) do
      create(:ee_ci_pipeline, ref: 'master', project: project, user: project.creator)
    end

    it 'will not store a report' do
      expect(Projects::XrayReport).not_to receive(:upsert)

      execute
    end
  end

  describe '#log_event' do
    let(:pipeline) do
      create(:ee_ci_pipeline, ref: 'master', project: project, user: project.creator)
    end

    it 'will log the proper context' do
      expect(Gitlab::AppLogger).to receive(:info).with(hash_including({ message: 'store_repository_xray' }))

      described_class.send(:log_event, { action: 'test' })
    end
  end
end
