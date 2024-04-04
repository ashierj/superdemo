# frozen_string_literal: true

module Namespaces
  module BlockSeatOverages
    class AlertComponent < ViewComponent::Base
      include SafeFormatHelper

      def initialize(resource:, content_class:, current_user:)
        @root_namespace = resource.root_ancestor
        @content_class = content_class
        @current_user = current_user
      end

      attr_reader :root_namespace, :content_class, :current_user

      def render?
        root_namespace.block_seat_overages? && root_namespace.seat_overage?
      end

      def title
        text = if owner?
                 s_("BlockSeatOverages|Your top-level group %{root_namespace_name} is now read-only.")
               else
                 s_("BlockSeatOverages|The top-level group %{root_namespace_name} is now read-only.")
               end

        safe_format(text, root_namespace_name: root_namespace.name)
      end

      def body
        body_data = link_data.merge({ root_namespace_name: root_namespace.name })

        if owner?
          safe_format(s_("BlockSeatOverages|%{root_namespace_name} has exceeded the number of seats in its " \
                         "subscription and is now %{link_start}read-only%{link_end}. To remove the read-only state, " \
                         "reduce the number of users in your top-level group to make seats available, or purchase " \
                         "more seats for the subscription."), body_data)
        else
          safe_format(s_("BlockSeatOverages|To remove the %{link_start}read-only%{link_end} state, ask a user " \
                         "with the Owner role for %{root_namespace_name} to reduce the number of users in the group, " \
                         "or to purchase more seats for the subscription."), body_data)
        end
      end

      def owner?
        Ability.allowed?(current_user, :owner_access, root_namespace)
      end

      private

      def link_data
        link = link_to('', help_page_path('user/read_only_namespaces'), target: '_blank', rel: 'noopener noreferrer')

        tag_pair(link, :link_start, :link_end)
      end
    end
  end
end
