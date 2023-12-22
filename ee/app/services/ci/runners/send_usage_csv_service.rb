# frozen_string_literal: true

module Ci
  module Runners
    # Sends a CSV report containing the runner usage for a given period
    #   (based on ClickHouse's ci_used_minutes_mv view)
    #
    class SendUsageCsvService
      # @param [User] current_user The user performing the reporting
      # @param [Symbol] runner_type The type of runners to report on, or nil to report on all types
      # @param [Date] from_date The start date of the period to examine
      # @param [Date] to_date The end date of the period to examine
      # @param [Integer] max_project_count The maximum number of projects in the report. All others will be folded
      #   into an 'Other projects' entry
      def initialize(current_user:, runner_type:, from_date:, to_date:, max_project_count:)
        @current_user = current_user
        @runner_type = runner_type
        @from_date = from_date
        @to_date = to_date
        @max_project_count = max_project_count
      end

      def execute
        generate_csv_service = GenerateUsageCsvService.new(
          current_user: @current_user,
          runner_type: @runner_type,
          from_date: @from_date,
          to_date: @to_date,
          max_project_count: @max_project_count
        )
        result = generate_csv_service.execute

        return result if result.error?

        Notify.runner_usage_by_project_csv_email(
          user: @current_user, from_date: @from_date, to_date: @to_date,
          csv_data: result.payload[:csv_data], export_status: result.payload[:status]
        ).deliver_now

        ServiceResponse.success(payload: result.payload.slice(:status))
      end
    end
  end
end
