# frozen_string_literal: true

module PackageMetadata
  class AdvisoryScanService
    def self.execute(advisory, global:)
      ::Gitlab::VulnerabilityScanning::AdvisoryScanner.scan_projects_for(advisory, global: global)
    end
  end
end
