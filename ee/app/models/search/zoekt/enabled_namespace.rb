# frozen_string_literal: true

module Search
  module Zoekt
    class EnabledNamespace < ApplicationRecord
      self.table_name = 'zoekt_enabled_namespaces'

      belongs_to :namespace, class_name: 'Namespace',
        foreign_key: :root_namespace_id, inverse_of: :zoekt_enabled_namespace

      has_many :indices, class_name: '::Search::Zoekt::Index',
        foreign_key: :zoekt_enabled_namespace_id, inverse_of: :zoekt_enabled_namespace
      has_many :nodes, through: :indices

      validate :only_root_namespaces_can_be_indexed

      scope :for_root_namespace_id, ->(root_namespace_id) { where(root_namespace_id: root_namespace_id) }
      scope :preload_storage_statistics, -> { includes(namespace: :root_storage_statistics) }
      scope :recent, -> { order(id: :desc) }
      scope :search_enabled, -> { where(search: true) }
      scope :with_limit, ->(maximum) { limit(maximum) }
      scope :with_missing_indices, -> { left_joins(:indices).where(zoekt_indices: { zoekt_enabled_namespace_id: nil }) }

      private

      def only_root_namespaces_can_be_indexed
        return if namespace&.root?

        errors.add(:root_namespace_id, 'Only root namespaces can be indexed')
      end
    end
  end
end
