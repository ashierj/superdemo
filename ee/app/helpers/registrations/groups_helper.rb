# frozen_string_literal: true

module Registrations
  module GroupsHelper
    def active_tab_classes
      experiment(:default_to_import_tab, actor: current_user) do |e|
        e.control { { create_tab: 'active', import_tab: '' } }
        e.candidate { { create_tab: '', import_tab: 'active' } }
      end.run
    end
  end
end
