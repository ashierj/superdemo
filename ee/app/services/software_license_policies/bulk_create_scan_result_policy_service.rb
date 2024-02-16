# frozen_string_literal: true

module SoftwareLicensePolicies
  class BulkCreateScanResultPolicyService < ::BaseService
    BATCH_SIZE = 250

    def initialize(project, params)
      super(project, nil, params)
    end

    def execute
      create_unknown_licenses

      licenses = SoftwareLicense.by_name(license_names).to_h do |license|
        [license.name, license.id]
      end

      result = software_license_policies(licenses)

      result.each_slice(BATCH_SIZE) do |batch|
        SoftwareLicensePolicy.insert_all(batch)
      end

      success(software_license_policy: result)
    end

    private

    def software_license_policies(licenses)
      params.filter_map do |policy_params|
        record = SoftwareLicensePolicy.new(
          project_id: project.id,
          software_license_id: licenses[policy_params[:name].strip],
          classification: policy_params[:approval_status],
          scan_result_policy_id: policy_params[:scan_result_policy_read]&.id
        )

        next if record.scan_result_policy_id.nil? || record.invalid?

        record.attributes.compact
      end
    end

    def create_unknown_licenses
      license_names.each_slice(BATCH_SIZE) do |names|
        SoftwareLicense.upsert_all(names.map { |l| { name: l } }, unique_by: :name, returning: %w[name id])
      end
    end

    def license_names
      params.map { |license| license.with_indifferent_access[:name].strip }
    end
  end
end
