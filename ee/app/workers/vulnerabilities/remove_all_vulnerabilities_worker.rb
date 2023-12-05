# frozen_string_literal: true

module Vulnerabilities
  class RemoveAllVulnerabilitiesWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executing, including_scheduled: true
    urgency :low
    data_consistency :delayed

    feature_category :vulnerability_management

    BATCH_SIZE = 500

    MODELS_TO_DROP_BY_PROJECT_ID = [
      Vulnerabilities::Read,
      Vulnerabilities::Finding,
      Vulnerabilities::Feedback,
      Vulnerabilities::HistoricalStatistic,
      Vulnerabilities::Identifier,
      Vulnerabilities::Scanner,
      Vulnerabilities::Statistic
    ].freeze

    MODELS_TO_DROP_BY_FINDING_ID = [
      Vulnerabilities::FindingLink,
      Vulnerabilities::FindingPipeline,
      Vulnerabilities::FindingRemediation
    ].freeze

    MODELS_TO_DROP_BY_VULNERABILITY_ID = [
      Vulnerabilities::MergeRequestLink,
      Vulnerabilities::IssueLink,
      Vulnerabilities::ExternalIssueLink,
      Vulnerabilities::StateTransition,
      VulnerabilityUserMention
    ].freeze

    def perform(project_id)
      Vulnerability.with_project(project_id).each_batch(of: BATCH_SIZE) do |batch|
        vulnerability_ids = batch.pluck(:id) # rubocop:disable CodeReuse/ActiveRecord -- there's no simple way to create a scope to use with EachBatch
        finding_ids = Vulnerabilities::Finding.ids_by_vulnerability(vulnerability_ids)

        Vulnerability.transaction do
          drop_by_finding_id(finding_ids)
          drop_by_project_id(project_id)
          drop_by_vulnerability_id(vulnerability_ids)
          batch.delete_all
        end
      end
    end

    private

    def drop_by_project_id(project_id)
      MODELS_TO_DROP_BY_PROJECT_ID.each do |model|
        loop do
          deleted = model.by_projects(project_id).limit(BATCH_SIZE).delete_all
          break if deleted == 0
        end
      end
    end

    def drop_by_finding_id(finding_ids)
      MODELS_TO_DROP_BY_FINDING_ID.each do |model|
        loop do
          deleted = model.by_finding_id(finding_ids).limit(BATCH_SIZE).delete_all
          break if deleted == 0
        end
      end
    end

    def drop_by_vulnerability_id(vulnerability_ids)
      MODELS_TO_DROP_BY_VULNERABILITY_ID.each do |model|
        loop do
          deleted = model.by_vulnerability(vulnerability_ids).limit(BATCH_SIZE).delete_all
          break if deleted == 0
        end
      end
    end
  end
end
