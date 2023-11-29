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

    # rubocop:disable Style/SymbolProc -- for some reason, using &:delete_all fails with wrong number of arguments
    def drop_by_project_id(project_id)
      MODELS_TO_DROP_BY_PROJECT_ID.each do |model|
        model
          .by_projects(project_id)
          .each_batch(of: BATCH_SIZE) { |b| b.delete_all }
      end
    end

    def drop_by_finding_id(finding_ids)
      MODELS_TO_DROP_BY_FINDING_ID.each do |model|
        model
          .by_finding_id(finding_ids)
          .each_batch(of: BATCH_SIZE) { |b| b.delete_all }
      end
    end

    def drop_by_vulnerability_id(vulnerability_ids)
      MODELS_TO_DROP_BY_VULNERABILITY_ID.each do |model|
        model
          .by_vulnerability(vulnerability_ids)
          .each_batch(of: BATCH_SIZE) { |b| b.delete_all }
      end
    end
    # rubocop:enable Style/SymbolProc
  end
end
