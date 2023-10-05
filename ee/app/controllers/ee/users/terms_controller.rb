# frozen_string_literal: true

module EE
  module Users
    module TermsController
      extend ActiveSupport::Concern

      prepended do
        include GoogleAnalyticsCSP

        before_action only: [:index] do
          push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
        end
      end
    end
  end
end
