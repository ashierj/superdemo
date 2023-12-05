# frozen_string_literal: true

module EE
  module API
    module Entities
      class SamlGroupLink < Grape::Entity
        expose :saml_group_name, as: :name, documentation: { type: 'string', example: 'saml-group-1' }
        expose :access_level, documentation: { type: 'integer', example: 40 }
        expose :member_role_id, documentation: { type: 'integer', example: 12 }, if: ->(instance, _options) do
          instance.group.custom_roles_enabled? && ::Feature.enabled?(:custom_roles_for_saml_group_links)
        end
      end
    end
  end
end
