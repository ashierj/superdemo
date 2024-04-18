# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          class Analytics < QA::Page::Base
            include QA::Page::Settings::Common

            view 'ee/app/views/projects/settings/analytics/_data_sources.html.haml' do
              element 'data-sources-content'
            end

            def expand_data_sources(&block)
              expand_content('data-sources-content') do
                DataSources.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
