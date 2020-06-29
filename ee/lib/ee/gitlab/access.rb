# frozen_string_literal: true

# Gitlab::Access module
#
# Define allowed roles that can be used
# in GitLab code to determine authorization level
#
module EE
  module Gitlab
    module Access
      extend ActiveSupport::Concern
      ADMIN = 60

      class_methods do
        def vulnerability_access_levels
          @vulnerability_access_levels ||= options_with_owner.except('Guest')
        end
      end
    end
  end
end
