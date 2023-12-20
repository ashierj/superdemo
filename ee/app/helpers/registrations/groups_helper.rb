# frozen_string_literal: true

module Registrations
  module GroupsHelper
    def active_tab_classes
      default = { create_tab: 'active', import_tab: '' }

      experiment(:default_to_import_tab, actor: current_user) do |e|
        e.control { default }
        e.candidate do
          if current_user.user_detail.registration_objective == 'move_repository'
            { create_tab: '', import_tab: 'active' }
          else
            default
          end
        end
      end.run
    end
  end
end
