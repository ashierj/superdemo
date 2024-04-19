# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class OnDemandScans < QA::Page::Base
            view 'ee/app/assets/javascripts/on_demand_scans/components/on_demand_scans.vue' do
              element 'new-scan-link'
            end

            def click_new_scan_link
              # If we have not already created a scan
              if has_no_element?('new-scan-link')
                # Empty state button
                click_link('New scan')
              else
                # Non-empty state button
                click_element('new-scan-link')
              end
            end

            def scan_is_present(scan_name, url)
              has_element?('truncate-end-container', text: scan_name) &&
                has_element?('truncate-end-container', text: url)
            end
          end
        end
      end
    end
  end
end
