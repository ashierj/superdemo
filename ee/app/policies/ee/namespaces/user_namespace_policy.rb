# frozen_string_literal: true

module EE
  module Namespaces
    module UserNamespacePolicy
      extend ActiveSupport::Concern

      prepended do
        condition(:read_only, scope: :subject) { @subject.read_only? }
        condition(:compliance_framework_available, scope: :subject) do
          @subject.licensed_feature_available?(:custom_compliance_frameworks)
        end

        rule { admin & is_gitlab_com }.enable :update_subscription_limit

        rule { read_only }.policy do
          prevent :create_projects
        end
        rule { can?(:owner_access) & compliance_framework_available }.enable :admin_compliance_framework
      end
    end
  end
end
