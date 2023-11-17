# frozen_string_literal: true

module API
  class GroupApprovalRules < ::API::Base
    include PaginationParams

    before { authenticate! }
    before { check_feature_availability }
    before { check_feature_flag }

    helpers ::API::Helpers::GroupApprovalRulesHelpers

    feature_category :source_code_management

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approval_rules' do
        desc 'Create new group approval rule' do
          success EE::API::Entities::GroupApprovalRule
        end
        params do
          use :create_group_approval_rule
        end
        post do
          create_group_approval_rule(present_with: EE::API::Entities::GroupApprovalRule)
        end
      end
    end
  end
end
