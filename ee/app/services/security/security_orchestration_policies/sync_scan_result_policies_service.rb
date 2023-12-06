# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncScanResultPoliciesService
      def initialize(configuration)
        @configuration = configuration
        @sync_project_service = SyncScanResultPoliciesProjectService.new(configuration)
      end

      def execute
        projects.find_each do |project|
          @sync_project_service.execute(project.id)
        end
      end

      private

      attr_reader :configuration

      def projects
        @projects ||= if configuration.namespace?
                        configuration.namespace.all_projects.select(:id)
                      else
                        Project.id_in(configuration.project_id)
                      end
      end
    end
  end
end
