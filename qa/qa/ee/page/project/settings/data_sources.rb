# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          class DataSources < QA::Page::Base
            view 'ee/app/views/projects/settings/analytics/_configurator_settings.haml' do
              element 'snowplow-configurator-field'
            end

            view 'ee/app/views/projects/settings/analytics/_product_analytics.html.haml' do
              element 'collector-host-field'
              element 'cube-api-url-field'
              element 'cube-api-key-field'
              element 'save-changes-button'
            end

            def fill_snowplow_configurator(configurator)
              fill_element('snowplow-configurator-field', configurator)
            end

            def fill_collector_host(collector_host)
              fill_element('collector-host-field', collector_host)
            end

            def fill_cube_api_url(url)
              fill_element('cube-api-url-field', url)
            end

            def fill_cube_api_key(key)
              fill_element('cube-api-key-field', key)
            end

            def save_changes
              click_element('save-changes-button')
            end
          end
        end
      end
    end
  end
end
