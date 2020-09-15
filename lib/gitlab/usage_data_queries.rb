# frozen_string_literal: true

module Gitlab
  class UsageDataQueries < UsageData
    class << self
      def count(relation, column = nil, *rest)
        raw_sql(relation, column)
      end

      def distinct_count(relation, column = nil, *rest)
        raw_sql(relation, column, :distinct)
      end

      def redis_usage_data(counter = nil, &block)
        if block_given?
          { redis_usage_data_block: block.to_s }
        elsif counter.present?
          { redis_usage_data_counter: counter }
        end
      end

      private

      def raw_sql(relation, column, distinct = nil)
        column ||= relation.primary_key
        relation.select(relation.all.table[column].count(distinct)).to_sql
      end
    end
  end
end
