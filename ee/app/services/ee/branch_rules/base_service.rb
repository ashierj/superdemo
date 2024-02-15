# frozen_string_literal: true

module EE
  module BranchRules
    module BaseService
      extend ActiveSupport::Concern

      prepended do
        extend Forwardable

        def_delegators(:branch_rule, :approval_project_rules, :external_status_checks)
      end
    end
  end
end
