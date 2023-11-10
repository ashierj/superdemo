# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class Authorizer
          Response = Struct.new(:allowed, :message, keyword_init: true) do
            def allowed?
              allowed
            end
          end

          def self.context(context:)
            if context.resource && context.container
              authorization_container = container(container: context.container, user: context.current_user)
              if authorization_container.allowed?
                resource(resource: context.resource, user: context.current_user)
              else
                authorization_container
              end
            elsif context.resource
              resource(resource: context.resource, user: context.current_user)
            elsif context.container
              container(container: context.container, user: context.current_user)
            else
              user(user: context.current_user)
            end
          end

          def self.context_allowed?(context:)
            context(context: context).allowed?
          end

          def self.container(container:, user:)
            return Response.new(allowed: false, message: not_found_message) unless container.member?(user)

            allowed = Gitlab::Llm::StageCheck.available?(container, :chat)
            message = s_("This feature is only allowed in groups that enable this feature.") unless allowed

            Response.new(allowed: allowed, message: message)
          end

          def self.resource(resource:, user:)
            return Response.new(allowed: false, message: not_found_message) unless resource

            container = resource&.resource_parent

            return Response.new(allowed: false, message: not_found_message) unless container

            allowed = user.can?("read_#{resource.to_ability_name}", resource)

            return Response.new(allowed: false, message: not_found_message) unless allowed

            authorization_container = container(container: container, user: user)

            return authorization_container unless authorization_container.allowed?

            Response.new(allowed: true)
          end

          def self.user(user:)
            allowed = user.any_group_with_ai_available?
            message = s_("You do not have access to AI features.") unless allowed
            Response.new(allowed: allowed, message: message)
          end

          def self.not_found_message
            s_("I am sorry, I am unable to find what you are looking for.")
          end
        end
      end
    end
  end
end
