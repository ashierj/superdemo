# frozen_string_literal: true

module Ci
  module Runners
    # Sends a CSV report containing the runner usage for a given period
    #   (based on ClickHouse's ci_used_minutes_mv view)
    #
    class SendUsageCsvService
      # @param [User] current_user The user performing the reporting
      # @param [Symbol] runner_type The type of runners to report on. Defaults to nil, reporting on all runner types
      # @param [DateTime] from_time The start date of the period to examine. Defaults to start of last full month
      # @param [DateTime] to_time The end date of the period to examine. Defaults to end of month
      def initialize(current_user:, runner_type: nil, from_time: nil, to_time: nil)
        @current_user = current_user
        @runner_type = runner_type
        @from_time = from_time
        @to_time = to_time
      end

      def execute
        generate_csv_service = GenerateUsageCsvService.new(
          current_user: @current_user,
          runner_type: @runner_type,
          from_time: @from_time,
          to_time: @to_time
        )
        result = generate_csv_service.execute

        return result if result.error?

        Notify.runner_usage_by_project_csv_email(
          user: @current_user, from_time: generate_csv_service.from_time, to_time: generate_csv_service.to_time,
          csv_data: result.payload[:csv_data], export_status: result.payload[:status]
        ).deliver_now

        ServiceResponse.success(payload: result.payload.slice(:status))
      end
    end
  end
end
