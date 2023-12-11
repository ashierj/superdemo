# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnersAvailabilityBuilder
      include ::Gitlab::Utils::StrongMemoize

      def self.instance_for(project)
        key = "runner_availability_builder_instance_for_project_#{project.id}"

        ::Gitlab::SafeRequestStore.fetch(key) do
          new(project)
        end
      end

      def minutes_checker
        Gitlab::Ci::RunnersAvailability::Minutes.new(project, runner_matchers)
      end
      strong_memoize_attr :minutes_checker

      private

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def runner_matchers
        project.all_runners.active.online.runner_matchers
      end
      strong_memoize_attr :runner_matchers
    end
  end
end
