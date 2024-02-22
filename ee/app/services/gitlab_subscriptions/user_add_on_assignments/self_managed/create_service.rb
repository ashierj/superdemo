# frozen_string_literal: true

module GitlabSubscriptions
  module UserAddOnAssignments
    module SelfManaged
      class CreateService < ::GitlabSubscriptions::UserAddOnAssignments::BaseCreateService
        include Gitlab::Utils::StrongMemoize

        private

        attr_reader :add_on_purchase, :user

        def eligible_for_gitlab_duo_pro_seat?
          user.eligible_for_self_managed_gitlab_duo_pro?
        end
        strong_memoize_attr :eligible_for_gitlab_duo_pro_seat?
      end
    end
  end
end
