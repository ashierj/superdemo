# frozen_string_literal: true

module Users
  class DuoProTrialEligibleNamespacesFinder
    def initialize(user)
      @user = user
    end

    def execute
      return Namespace.none if GitlabSubscriptions::AddOn.code_suggestions.none?

      user.owned_groups.not_in_default_plan.not_duo_pro_or_no_add_on.ordered_by_name
    end

    private

    attr_reader :user
  end
end
