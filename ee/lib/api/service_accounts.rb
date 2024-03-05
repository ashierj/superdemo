# frozen_string_literal: true

module API
  class ServiceAccounts < ::API::Base
    extend ActiveSupport::Concern

    before { authenticated_as_admin! }

    resource :service_accounts do
      desc 'Create a service account user. Available only for instance admins.' do
        success Entities::UserBasic
      end

      params do
        optional :name, type: String, desc: 'Name of the user'
        optional :username, type: String, desc: 'Username of the user'
      end

      post feature_category: :user_management do
        response = ::Users::ServiceAccounts::CreateService.new(current_user, declared_params).execute

        if response.status == :success
          present response.payload, with: ::API::Entities::UserBasic, current_user: current_user
        elsif response.reason == :forbidden
          forbidden!(response.message)
        else
          bad_request!(response.message)
        end
      end
    end
  end
end
