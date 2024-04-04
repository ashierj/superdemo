# frozen_string_literal: true

module Search
  module Zoekt
    class RoutingService
      MAX_NUMBER_OF_PROJECTS = 30_000

      attr_reader :projects

      def initialize(projects)
        @projects = projects
      end

      # Generates a routing map of zoekt nodes to project ids
      # this is needed to send search requests to appropriate nodes
      # @returns [Hash] { node_id => [1,2,3], node_id2 => [4,5,6] }
      # rubocop:disable CodeReuse/ActiveRecord -- this service builds a complex custom AR query
      def execute
        raise "Too many projects" if projects.count > MAX_NUMBER_OF_PROJECTS

        searcheable_states_enum = Search::Zoekt::Index.states.slice(*Search::Zoekt::Index::SEARCHEABLE_STATES).values

        result = projects.without_order
          .joins_namespace
          .joins('INNER JOIN zoekt_indices ON zoekt_indices.namespace_id = namespaces.traversal_ids[1]')
          .joins('INNER JOIN zoekt_enabled_namespaces ON zoekt_indices.zoekt_enabled_namespace_id = zoekt_enabled_namespaces.id') # rubocop:disable Layout/LineLength -- No need to break the line
          .where(zoekt_enabled_namespaces: { search: true }, zoekt_indices: { state: searcheable_states_enum })
          .pluck(:id, :zoekt_node_id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- we restrict the number of projects in the guard clause

        mapped_result = result.group_by(&:last).transform_values { |v| v.map(&:first) }
        sorted = mapped_result.sort_by { |_, v| v.count }.reverse

        {}.tap do |hash|
          processed = Set.new
          sorted.each do |node_id, project_ids|
            project_ids.each do |project_id|
              next if processed.include?(project_id)

              hash[node_id] ||= []
              hash[node_id] << project_id
              processed << project_id
            end
          end
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def self.execute(...)
        new(...).execute
      end
    end
  end
end
