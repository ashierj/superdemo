# frozen_string_literal: true

module EE
  module WorkItemPolicy
    extend ActiveSupport::Concern
    class_methods do
      def synced_work_item_disallowed_abilities
        ::WorkItemPolicy.ability_map.map.keys.select { |ability| !ability.to_s.starts_with?("read_") }
      end
    end

    prepended do
      rule { has_synced_epic }.policy do
        prevent(*synced_work_item_disallowed_abilities)
      end
    end
  end
end
