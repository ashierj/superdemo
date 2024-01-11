# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          class PipelineSubscriptions < QA::Page::Base
            view 'ee/app/views/projects/settings/subscriptions/_table.html.haml' do
              element 'add-new-subscription'
              element 'upstream-project-path-field'
              element 'subscribe-button'
            end

            def subscribe(project_path)
              click_element('add-new-subscription')
              fill_element('upstream-project-path-field', project_path)
              click_element('subscribe-button')
            end
          end
        end
      end
    end
  end
end
