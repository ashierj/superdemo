# frozen_string_literal: true

module EE
  module Projects
    module RunnersController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          push_frontend_feature_flag(:google_cloud_support_feature_flag, @project&.root_ancestor)
        end
      end
    end
  end
end
