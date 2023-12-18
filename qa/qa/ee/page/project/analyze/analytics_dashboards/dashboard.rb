# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Analyze
          module AnalyticsDashboards
            class Dashboard < QA::Page::Base
              view 'ee/app/assets/javascripts/vue_shared/components/' \
                   'customizable_dashboard/customizable_dashboard.vue' do
                element 'grid-stack-panel'
              end

              def audience_dashboard_panels
                all_elements('grid-stack-panel', minimum: 9)
              end

              def behavior_dashboard_panels
                all_elements('grid-stack-panel', minimum: 5)
              end
            end
          end
        end
      end
    end
  end
end
