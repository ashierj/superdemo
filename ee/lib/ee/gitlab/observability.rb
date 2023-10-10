# frozen_string_literal: true

module EE
  module Gitlab
    module Observability
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        def tracing_url(project)
          "#{::Gitlab::Observability.observability_url}/v3/query/#{project.id}/traces"
        end
      end
    end
  end
end
