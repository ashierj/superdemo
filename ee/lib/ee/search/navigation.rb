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

      def show_epics_search_tab?
        project.nil? && !!options[:show_epics] && feature_flag_tab_enabled?(:global_search_epics_tab)
      end
    end
  end
end
