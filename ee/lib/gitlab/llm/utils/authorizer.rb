# frozen_string_literal: true

module Gitlab
  module Llm
    module Utils
      class Authorizer
        Response = Struct.new(:allowed, :message, keyword_init: true) do
          def allowed?
            allowed
          end
        end

        def self.container(container:, user:)
          if Feature.disabled?(:duo_features_enabled_setting, user) || user.can?(:access_duo_features, container)
            Response.new(allowed: true)
          else
            Response.new(allowed: false, message: container_not_allowed_message(container, user))
          end
        end

        def self.resource(resource:, user:)
          return Response.new(allowed: false, message: not_found_message) unless resource && user
          return user_as_resource(resource: resource, user: user) if resource.is_a?(User)

          allowed = user.can?("read_#{resource.to_ability_name}", resource)

          return Response.new(allowed: false, message: not_found_message) unless allowed

          authorization_container = container(container: resource.resource_parent, user: user)

          return authorization_container unless authorization_container.allowed?

          Response.new(allowed: true)
        end

        # Child classes may impose additional restrictions
        def self.user(user:) # rubocop:disable Lint/UnusedMethodArgument -- Argument used by child classes
          Response.new(allowed: true)
        end

        private_class_method def self.user_as_resource(resource:, user:)
          return Response.new(allowed: false, message: not_found_message) if user != resource

          user(user: user)
        end

        private_class_method def self.container_not_allowed_message(container, user)
          container.member?(user) ? no_ai_message : not_found_message
        end

        private_class_method def self.not_found_message
          s_("I am sorry, I am unable to find what you are looking for.")
        end

        private_class_method def self.no_access_message
          s_("You do not have access to chat feature.")
        end

        private_class_method def self.no_ai_message
          s_("This feature is only allowed in groups or projects that enable this feature.")
        end
      end
    end
  end
end
