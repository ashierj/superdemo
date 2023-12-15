# frozen_string_literal: true

module MemberRoles
  class BaseService < ::BaseService
    include Gitlab::Allowable

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    private

    attr_accessor :current_user, :params, :member_role

    def allowed?
      can?(current_user, :admin_member_role, member_role)
    end

    def authorized_error
      ::ServiceResponse.error(message: _('Operation not allowed'), reason: :unauthorized)
    end

    def group
      params[:namespace] || member_role&.namespace
    end
  end
end
