# frozen_string_literal: true

module EE
  module DashboardController
    extend ActiveSupport::Concern

    prepended do
      before_action only: :issues do
        push_frontend_feature_flag(:okrs_mvc)
      end
    end
  end
end
