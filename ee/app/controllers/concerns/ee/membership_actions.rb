# frozen_string_literal: true

module EE
  module MembershipActions
    extend ::Gitlab::Utils::Override

    override :leave
    def leave
      super

      if current_user.authorized_by_provisioning_group?(membershipable)
        sign_out current_user
      end
    end

    private

    def update_params
      super.merge(params.require(root_params_key).permit(:member_role_id))
    end

    override :update_success_response
    def update_success_response(result)
      response_data = {}
      response_data = super if result[:members].present?
      if result[:members_queued_for_approval].present?
        response_data[:message] = _('Some members were queued for approval')
      end

      response_data
    end
  end
end
