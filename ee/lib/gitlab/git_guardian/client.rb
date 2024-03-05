# frozen_string_literal: true

module Gitlab
  module GitGuardian
    class Client
      API_URL = "https://api.gitguardian.com/v1/multiscan"
      TIMEOUT = 5.seconds
      BATCH_SIZE = 20
      FILENAME_LIMIT = 256

      Error = Class.new(StandardError)
      ConfigError = Class.new(Error)
      RequestError = Class.new(Error)

      attr_reader :api_token

      def initialize(api_token)
        raise ConfigError, 'Please check your integration configuration.' unless api_token.present?

        @api_token = api_token
      end

      def execute(blobs = [])
        threaded_batches = []
        blobs.each_slice(BATCH_SIZE).map.with_object([]) do |blobs_batch, _|
          threaded_batches << execute_batched_request(blobs_batch)
        end

        threaded_batches.filter_map(&:value).flatten
      end

      private

      def execute_batched_request(blobs_batch)
        Thread.new do
          params = blobs_batch.map do |blob|
            blob_params = { document: blob.data }

            # GitGuardian limits filename field to 256 characters.
            # That is why we only pass file name, which is sufficient for Git Guardian to perform its checks.
            # See: https://api.gitguardian.com/docs#operation/multiple_scan
            if blob.path.present?
              filename = File.basename(blob.path)
              limited_filename = limit_filename(filename)

              blob_params[:filename] = limited_filename
            end

            blob_params
          end

          response = perform_request(params)
          blobs_paths = blobs_batch.map(&:path)
          policy_breaks = process_response(response, blobs_paths)

          policy_breaks.presence
        end
      end

      def limit_filename(filename)
        filename_size = filename.length
        over_limit = filename.length - FILENAME_LIMIT
        return filename if over_limit <= 0

        # We splice the filename to keep it under 256 characters
        # in a First-In-First-Out to keep the file extension
        # which is necessary to some GitGuardian policies checks
        filename[over_limit..filename_size]
      end

      def perform_request(params)
        options = {
          headers: headers,
          body: params.to_json,
          timeout: TIMEOUT
        }

        response = Gitlab::HTTP.post(API_URL, options)

        raise RequestError, "HTTP status code #{response.code}" unless response.success?

        response
      end

      def headers
        {
          'Content-Type': 'application/json',
          Authorization: "Token #{api_token}"
        }
      end

      def process_response(response, file_paths)
        parsed_response = Gitlab::Json.parse(response.body)

        parsed_response.map.with_index do |policy_break_for_file, blob_index|
          next if policy_break_for_file['policy_break_count'] == 0

          file_path = file_paths[blob_index]

          policy_break_for_file['policy_breaks'].map do |policy_break|
            violation_match = policy_break['matches'].first
            match_type = violation_match['type']
            match_value = violation_match['match']
            file_path_substring = file_path.present? ? " at '#{file_path}'" : ''

            "#{policy_break['policy']} policy violated#{file_path_substring} for #{match_type} '#{match_value}'"
          end
        end.compact.flatten
      rescue JSON::ParserError
        raise Error, 'invalid response format'
      end
    end
  end
end
