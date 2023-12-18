# frozen_string_literal: true

module EE
  module API
    module Entities
      module UserPreferences
        extend ActiveSupport::Concern

        prepended do
          expose :code_suggestions, if: ->(_preferences, options) do
            ::Feature.disabled?(:code_suggestions_used_by_default, options[:current_user])
          end
        end
      end
    end
  end
end
