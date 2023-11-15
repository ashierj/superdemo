# frozen_string_literal: true

module EE
  module Groups
    module WorkItemsController
      extend ActiveSupport::Concern
      include ::Gitlab::Utils::StrongMemoize

      prepended do
        before_action :authorize_read_work_item!, only: [:description_diff, :delete_description_version]

        include DescriptionDiffActions
      end

      private

      def issuable
        ::WorkItem.find_by_namespace_and_iid!(group, params[:iid])
      end
      strong_memoize_attr :issuable

      def authorize_read_work_item!
        access_denied! unless can?(current_user, :read_work_item, issuable)
      end
    end
  end
end
