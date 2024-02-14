# frozen_string_literal: true

module Keeps
  module Helpers
    class Milestones
      Error = Class.new(StandardError)

      def before_cuttoff?(milestone:, milestones_ago:)
        Gem::Version.new(milestone) < Gem::Version.new(past_milestone(milestones_ago: milestones_ago))
      end

      private

      def current_milestone
        milestone = File.read(File.expand_path('../../VERSION', __dir__))
        milestone.gsub(/^(\d+\.\d+).*$/, '\1').chomp
      end

      def past_milestone(milestones_ago:)
        major, minor = current_milestone.split(".").map(&:to_i)

        older_major =
          if minor >= milestones_ago
            major
          else
            major - (((milestones_ago - minor - 1) / 13) + 1)
          end

        older_minor = (0..12).to_a[(minor - milestones_ago) % 13]

        [older_major, older_minor].join(".")
      end
    end
  end
end
