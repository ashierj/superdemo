# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Analyze
          module AnalyticsDashboards
            class Initial < QA::Page::Base
              view 'ee/app/assets/javascripts/analytics/analytics_dashboards/components/list/feature_list_item.vue' do
                element 'setup-button'
              end

              def click_set_up
                wait_for_set_up_button
                click_element('setup-button')
              end

              def wait_for_set_up_button
                retry_until(max_attempts: 5, reload: true) do
                  find_element('setup-button')
                end
              end
            end
          end
        end
      end
    end
  end
end
