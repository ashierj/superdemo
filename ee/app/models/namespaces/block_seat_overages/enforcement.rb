# frozen_string_literal: true

module Namespaces
  module BlockSeatOverages
    class Enforcement
      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def git_check_seat_overage!(error_class)
        return unless root_namespace.block_seat_overages? && root_namespace.seat_overage?

        raise error_class,
          s_("BlockSeatOverages|Your top-level group is over the number of seats in its " \
             "subscription and has been placed in a read-only state.")
      end

      private

      attr_reader :root_namespace
    end
  end
end
