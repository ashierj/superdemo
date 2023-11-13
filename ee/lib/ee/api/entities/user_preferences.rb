# frozen_string_literal: true

module EE
  module API
    module Entities
      module UserPreferences
        extend ActiveSupport::Concern

        prepended do
          expose :code_suggestions
        end
      end
    end
  end
end
