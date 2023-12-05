# frozen_string_literal: true

module API
  class Chat < ::API::Base
    include APIGuard

    feature_category :duo_chat

    allow_access_with_scope :ai_features

    AVAILABLE_RESOURCES = %w[issue epic group project].freeze

    before do
      authenticate!

      not_found! unless Feature.enabled?(:access_rest_chat, current_user)
    end

    helpers do
      def user_allowed?(resource)
        current_user.can?("read_#{resource.to_ability_name}", resource) &&
          Llm::ChatService.new(current_user, resource).valid?
      end

      def find_resource(parameters)
        return current_user unless parameters[:resource_type] && parameters[:resource_id]

        object = parameters[:resource_type].camelize.safe_constantize
        object.find(parameters[:resource_id])
      end

      def reset_chat(action_name, message_attributes)
        message_attributes[:content] = '/reset'
        prompt_message = ::Gitlab::Llm::AiMessage.for(action: action_name).new(message_attributes)
        prompt_message.save!
      end
    end

    namespace 'chat' do
      resources :completions do
        params do
          requires :content, type: String, limit: 1000, desc: 'Prompt from user'
          optional :resource_type, type: String, limit: 100, values: AVAILABLE_RESOURCES, desc: 'Resource type'
          optional :resource_id, type: Integer, desc: 'ID of resource.'
          optional :referer_url, type: String, limit: 1000, desc: 'Referer URL'
          optional :client_subscription_id, type: String, limit: 500, desc: 'Client Subscription ID'
          optional :with_clean_history, type: Boolean,
            desc: 'Indicates if we need to reset the history before and after the request'
        end
        post do
          safe_params = declared_params(include_missing: false)
          resource = find_resource(safe_params)

          not_found! unless user_allowed?(resource)
          action_name = 'chat'

          options = safe_params.slice(:referer_url)
          message_attributes = {
            request_id: SecureRandom.uuid,
            role: ::Gitlab::Llm::AiMessage::ROLE_USER,
            ai_action: action_name,
            user: current_user,
            context: ::Gitlab::Llm::AiMessageContext.new(resource: resource),
            client_subscription_id: safe_params[:client_subscription_id]
          }

          reset_chat(action_name, message_attributes) if safe_params[:with_clean_history]

          message_attributes[:content] = safe_params[:content]

          prompt_message = ::Gitlab::Llm::AiMessage.for(action: action_name).new(message_attributes)
          ai_response = Llm::Internal::CompletionService.new(prompt_message, options).execute

          reset_chat(action_name, message_attributes) if safe_params[:with_clean_history]

          present ai_response.response_body
        end
      end
    end
  end
end
