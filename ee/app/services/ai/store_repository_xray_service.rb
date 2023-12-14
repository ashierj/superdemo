# frozen_string_literal: true

module Ai
  class StoreRepositoryXrayService
    include Gitlab::Utils::Gzip

    def self.execute(pipeline)
      new(pipeline).execute
    end

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      pipeline.job_artifacts.repository_xray.each do |artifact|
        artifact.each_blob do |blob, filename|
          blob.each_line do |line|
            lang = File.basename(filename, '.json')
            begin
              content = ::Gitlab::Json.parse(line)
              Projects::XrayReport
                .upsert(
                  { project_id: pipeline.project_id, payload: content, lang: lang, file_checksum: content['checksum'] },
                  unique_by: [:project_id, :lang]
                )
            rescue JSON::ParserError => e
              self.class.log_event({ action: 'xray_report_parse', error: "Parsing failed #{e}" })
            end
          end
        end
      end
    end

    def self.log_event(log_fields)
      Gitlab::AppLogger.info(
        message: 'store_repository_xray',
        **log_fields
      )
    end

    private

    attr_reader :pipeline

    delegate :project, to: :pipeline, private: true
  end
end
