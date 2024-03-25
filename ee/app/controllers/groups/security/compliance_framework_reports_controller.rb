# frozen_string_literal: true

module Groups
  module Security
    class ComplianceFrameworkReportsController < Groups::ApplicationController
      include Groups::SecurityFeaturesHelper

      before_action :authorize_compliance_dashboard!

      feature_category :compliance_management

      def index
        if feature_enabled?
          ComplianceManagement::Frameworks::ExportService.new(
            user: current_user,
            group: group
          ).email_export

          flash[:notice] = _('After the report is generated, an email will be sent with the report attached.')
        end

        redirect_to group_security_compliance_dashboard_path(group, vueroute: :frameworks)
      end

      private

      def feature_enabled?
        Feature.enabled?(:compliance_frameworks_report_csv_export, group)
      end
    end
  end
end
