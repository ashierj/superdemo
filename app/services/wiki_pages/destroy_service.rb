# frozen_string_literal: true

module WikiPages
  class DestroyService < WikiPages::BaseService
    def execute(page)
      if page.delete
        execute_hooks(page)
        ServiceResponse.success(payload: { page: page })
      else
        message = page.template? ? _('Could not delete wiki template') : _('Could not delete wiki page')
        ServiceResponse.error(message: message, payload: { page: page })
      end
    end

    def usage_counter_action
      :delete
    end

    def external_action
      'delete'
    end

    def event_action
      :destroyed
    end

    def fingerprint(page)
      page.wiki.repository.head_commit.sha
    end
  end
end
