# frozen_string_literal: true

module Projects
  module Security
    class DastScannerProfilesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action do
        authorize_read_on_demand_dast_scan!
        push_frontend_feature_flag(:dast_ods_browser_based_scanner, project)
      end

      feature_category :dynamic_application_security_testing
      urgency :low

      def new
      end

      def edit
        @scanner_profile = @project
          .dast_scanner_profiles
          .find(params[:id])
      end
    end
  end
end
