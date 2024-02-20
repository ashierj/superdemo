# frozen_string_literal: true

module EE
  module Search
    module Navigation
      extend ::Gitlab::Utils::Override

      override :tabs
      def tabs
        super.merge(epics: { sort: 3, label: _("Epics"), condition: show_epics_search_tab? })
      end

      private

      def zoekt_enabled?
        !!options[:zoekt_enabled]
      end

      override :show_code_search_tab?
      def show_code_search_tab?
        return true if super
        return false unless project.nil?

        if show_elasticsearch_tabs?
          return true if group.present?

          return ::Feature.enabled?(:global_search_code_tab, user, type: :ops)
        end

        group.present? && zoekt_enabled? &&
          ::Search::Zoekt.search?(group) && ::Search::Zoekt.enabled_for_user?(user)
      end

      override :show_wiki_search_tab?
      def show_wiki_search_tab?
        return true if super

        return false if project
        return false unless show_elasticsearch_tabs?
        return true if group

        ::Feature.enabled?(:global_search_wiki_tab, user, type: :ops)
      end

      def show_epics_search_tab?
        return false if project
        return false unless options[:show_epics]
        return true if group

        ::Feature.enabled?(:global_search_epics_tab, user, type: :ops)
      end
    end
  end
end
