# frozen_string_literal: true

module Search
  module Zoekt
    class Node < ApplicationRecord
      self.table_name = 'zoekt_nodes'

      has_many :indices,
        foreign_key: :zoekt_node_id, inverse_of: :node, class_name: '::Search::Zoekt::Index'
      has_many :enabled_namespaces,
        through: :indices, source: :zoekt_enabled_namespace, class_name: '::Search::Zoekt::EnabledNamespace'

      validates :index_base_url, presence: true
      validates :search_base_url, presence: true
      validates :uuid, presence: true, uniqueness: true
      validates :last_seen_at, presence: true
      validates :used_bytes, presence: true
      validates :total_bytes, presence: true
      validates :metadata, json_schema: { filename: 'zoekt_node_metadata' }

      attribute :metadata, :ind_jsonb # for indifferent access

      scope :descending_order_by_free_bytes, -> { order(Arel.sql('total_bytes - used_bytes').desc) }

      def self.find_or_initialize_by_task_request(params)
        params = params.with_indifferent_access

        find_or_initialize_by(uuid: params.fetch(:uuid)).tap do |s|
          # Note: if zoekt node makes task_request with a different `node.url`,
          # we will respect that and make change here.
          s.index_base_url = params.fetch("node.url")
          s.search_base_url = params['node.search_url'] || params.fetch("node.url")

          s.last_seen_at = Time.zone.now
          s.used_bytes = params.fetch("disk.used")
          s.total_bytes = params.fetch("disk.all")
          s.metadata['name'] = params.fetch("node.name")
        end
      end

      def backoff
        @backoff ||= ::Search::Zoekt::NodeBackoff.new(self)
      end
    end
  end
end
