# frozen_string_literal: true

module Gitlab
  module CustomRoles
    module Shared
      PARAMS = %i[
        name
        description
        introduced_by_issue
        introduced_by_mr
        feature_category
        milestone
        group_ability
        project_ability
        requirement
        skip_seat_consumption
      ].freeze
    end
  end
end
