# frozen_string_literal: true

module Ci
  module Runners
    # Sends a CSV report containing the runner usage for a given period
    #   (based on ClickHouse's ci_used_minutes_mv view)
    #
    class SendUsageCsvService
      # @param [User] current_user The user performing the reporting
      # @param [Symbol] runner_type The type of runners to report on. Defaults to nil, reporting on all runner types
      # @param [Date] from_date The start date of the period to examine. Defaults to start of last full month
      # @param [Date] to_date The end date of the period to examine. Defaults to end of month
      def initialize(current_user:, runner_type: nil, from_date: nil, to_date: nil)
        @current_user = current_user
        @runner_type = runner_type
        @from_date = from_date
        @to_date = to_date
      end

      def execute
        generate_csv_service = GenerateUsageCsvService.new(
          current_user: @current_user,
          runner_type: @runner_type,
          from_date: @from_date,
          to_date: @to_date
        )
        result = generate_csv_service.execute

        return result if result.error?

        Notify.runner_usage_by_project_csv_email(
          user: @current_user, from_date: generate_csv_service.from_date, to_date: generate_csv_service.to_date,
          csv_data: result.payload[:csv_data], export_status: result.payload[:status]
        ).deliver_now

        ServiceResponse.success(payload: result.payload.slice(:status))
      end
    end
  end
end
