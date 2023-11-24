# frozen_string_literal: true

module Gitlab
  module Llm
    class FeatureAuthorizer
      def initialize(container:, current_user:, feature_name:)
        @container = container
        @current_user = current_user
        @feature_name = feature_name
      end

      def allowed?
        return false unless Feature.enabled?(:ai_global_switch, type: :ops)
        return false unless container && current_user
        return false unless container.member?(current_user)

        ::Gitlab::Llm::StageCheck.available?(container, feature_name)
      end

      private

      attr_reader :container, :current_user, :feature_name
    end
  end
end
