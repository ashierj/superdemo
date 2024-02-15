# frozen_string_literal: true

module Gitlab
  module Checks
    class IntegrationsCheck < ::Gitlab::Checks::BaseBulkChecker
      def validate!
        ::Gitlab::Checks::Integrations::GitGuardianCheck.new(self).validate!
      end
    end
  end
end
