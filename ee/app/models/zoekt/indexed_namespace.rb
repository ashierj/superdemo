# frozen_string_literal: true

module Zoekt
  class IndexedNamespace < ApplicationRecord
    include IgnorableColumns

    def self.table_name_prefix
      'zoekt_'
    end

    ignore_column :zoekt_shard_id, remove_with: '16.8', remove_after: '2024-01-18'

    belongs_to :node, foreign_key: :zoekt_node_id, inverse_of: :indexed_namespaces, class_name: '::Search::Zoekt::Node'
    belongs_to :namespace

    validates :search, inclusion: [true, false]
    validate :only_root_namespaces_can_be_indexed

    scope :recent, -> { order(id: :desc) }
    scope :with_limit, ->(maximum) { limit(maximum) }
    scope :search_enabled, -> { where(search: true) }

    after_commit :index, on: :create
    after_commit :delete_from_index, on: :destroy

    def self.for_node_and_namespace!(node:, namespace:)
      find_by!(node: node, namespace: namespace)
    end

    def self.find_or_create_for_node_and_namespace!(node:, namespace:)
      find_or_create_by!(node: node, namespace: namespace)
    end

    def self.for_namespace(namespace)
      where(namespace: namespace)
    end

    private

    def only_root_namespaces_can_be_indexed
      return unless namespace.has_parent?

      errors.add(:base, 'Only root namespaces can be indexed')
    end

    def index
      ::Search::Zoekt::NamespaceIndexerWorker.perform_async(namespace_id, :index)
    end

    def delete_from_index
      ::Search::Zoekt::NamespaceIndexerWorker.perform_async(namespace_id, :delete, zoekt_node_id)
    end
  end
end
